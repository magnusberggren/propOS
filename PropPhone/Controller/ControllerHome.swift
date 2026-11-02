//
//  ControllerHome.swift
//  PropPhone
//
//  The operator's board: scene control with GO/RESET, connected
//  devices with live mirrors, and the phone library. Deliberately
//  plain iOS design — this is the tool, not the prop.
//

import SwiftUI

struct ControllerHome: View {
    @Environment(ShowStore.self) private var store
    @AppStorage("appRole") private var roleRaw = ""

    @State private var session = ControlSession()
    @State private var selectedSceneID: UUID?
    @State private var editingPhone: PhoneProfile?

    var body: some View {
        NavigationStack {
            List {
                devicesSection
                sceneSection
                phonesSection
            }
            .navigationTitle("PropOS")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        session.stop()
                        roleRaw = AppRole.none.rawValue
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let phone = PhoneProfile(name: "New Phone")
                        store.upsertPhone(phone)
                        editingPhone = phone
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editingPhone) { phone in
                PhoneProfileEditor(phone: phone)
            }
            .onAppear {
                session.start()
                if selectedSceneID == nil {
                    selectedSceneID = store.document.scenes.first?.id
                }
            }
        }
    }

    private var selectedScene: SceneSetup? {
        store.document.scenes.first { $0.id == selectedSceneID }
    }

    // MARK: - Devices

    private var devicesSection: some View {
        Section("Prop phones on set") {
            if session.devices.isEmpty {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Searching for prop phones…")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }

            ForEach(session.devices) { device in
                DeviceRow(session: session, device: device)
            }
        }
    }

    // MARK: - Scene control

    @ViewBuilder
    private var sceneSection: some View {
        Section("Scene") {
            if store.document.scenes.isEmpty {
                Text("No scenes yet. Create a phone, then add a scene from its editor.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Picker("Scene", selection: $selectedSceneID) {
                    ForEach(store.document.scenes) { scene in
                        Text(scene.name).tag(Optional(scene.id))
                    }
                }

                if let scene = selectedScene {
                    SceneControlPanel(session: session, scene: scene)
                }
            }
        }
    }

    // MARK: - Phones

    private var phonesSection: some View {
        Section("Phone library") {
            ForEach(store.document.phones) { phone in
                Button {
                    editingPhone = phone
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(phone.name)
                                .foregroundStyle(.primary)
                            Text("\(phone.contacts.count) contacts · \(phone.voicemails.count) voicemails")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .onDelete { indexSet in
                for i in indexSet {
                    store.deletePhone(id: store.document.phones[i].id)
                }
            }
        }
    }
}

// MARK: - Device row

struct DeviceRow: View {
    let session: ControlSession
    let device: ControlSession.Device

    var body: some View {
        HStack(spacing: 12) {
            // Live mirror of what the actor's phone is actually showing.
            Group {
                if let mirror = device.mirror {
                    MirrorThumbnail(state: mirror)
                } else {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(uiColor: .systemGray5))
                        .overlay {
                            Image(systemName: "iphone.gen3")
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(width: 38, height: 82)

            VStack(alignment: .leading, spacing: 3) {
                Text(device.name)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 5) {
                    Circle()
                        .fill(device.isConnected ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(device.isConnected ? "Connected" : "Connecting…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { device.receivesPushes },
                set: { session.setReceivesPushes($0, for: device.id) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 2)
    }
}

/// Scaled-down, non-interactive render of a reported PhoneState.
struct MirrorThumbnail: View {
    let state: PhoneState

    var body: some View {
        GeometryReader { geo in
            let screen = UIScreen.main.bounds.size
            let scale = geo.size.height / screen.height

            MirrorView(state: state)
                .frame(width: screen.width, height: screen.height)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: screen.width * scale, height: geo.size.height, alignment: .topLeading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

// MARK: - Scene control panel

struct SceneControlPanel: View {
    let session: ControlSession
    let scene: SceneSetup

    @State private var confirmReset = false

    var body: some View {
        // RESET: the money button. Re-applies the scene baseline —
        // voicemail dots, screen, clock, everything — in one tap.
        Button {
            session.loadState(scene.baseline)
        } label: {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                    .font(.body.weight(.semibold))
                Text(session.canonicalState == nil ? "Load scene on phones" : "RESET to top of scene")
                    .font(.body.weight(.semibold))
                Spacer()
            }
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Color.red, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))

        ForEach(scene.cues) { cue in
            HStack {
                Text(cue.name)
                    .font(.subheadline)
                Spacer()
                Button {
                    session.fire(cue.action)
                } label: {
                    Text("GO")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 7)
                        .background(Color.green, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(session.canonicalState == nil)
            }
        }

        QuickActionsRow(session: session, scene: scene)
    }
}

// MARK: - Quick actions

struct QuickActionsRow: View {
    let session: ControlSession
    let scene: SceneSetup

    @State private var showTextSheet = false

    private var liveProfile: PhoneProfile {
        session.canonicalState?.profile ?? scene.baseline.profile
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                quick("Lock", "lock.iphone") { session.fire(.setScreen(.lockScreen)) }
                quick("Home", "square.grid.3x3") { session.fire(.setScreen(.home)) }
                quick("Voicemail", "recordingtape") {
                    session.fire(.setScreen(.phoneApp(PhoneAppState(tab: .voicemail))))
                }
                quick("Messages", "message") {
                    session.fire(.setScreen(.messagesApp(MessagesAppState())))
                }
                quick("Photos", "photo.on.rectangle") {
                    session.fire(.setScreen(.photosApp(PhotosAppState())))
                }
                quick("Black", "circle.fill") {
                    let isBlack = session.canonicalState?.blackout ?? false
                    session.fire(.blackout(!isBlack))
                }
                quick("Clear notifs", "bell.slash") { session.fire(.clearNotifications) }

                Menu {
                    ForEach(liveProfile.contacts) { contact in
                        Button(contact.displayName) {
                            session.fire(.incomingCall(.from(contact: contact)))
                        }
                    }
                } label: {
                    quickLabel("Call from…", "phone.arrow.down.left")
                }
                .disabled(session.canonicalState == nil)

                quick("Send text…", "text.bubble") { showTextSheet = true }
            }
            .padding(.vertical, 2)
        }
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 0))
        .sheet(isPresented: $showTextSheet) {
            QuickTextSheet(session: session, profile: liveProfile)
                .presentationDetents([.medium])
        }
    }

    private func quick(_ label: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            quickLabel(label, symbol)
        }
        .buttonStyle(.plain)
        .disabled(session.canonicalState == nil)
    }

    private func quickLabel(_ label: String, _ symbol: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.footnote)
            Text(label)
                .font(.footnote.weight(.medium))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemGray5), in: Capsule())
        .foregroundStyle(.primary)
    }
}

// MARK: - Quick text sheet

/// Live-drop a text into a thread on the prop phone: pick the sender,
/// optionally show the typing bubble first, then send.
struct QuickTextSheet: View {
    let session: ControlSession
    let profile: PhoneProfile

    @Environment(\.dismiss) private var dismiss
    @State private var threadID: UUID?
    @State private var text = ""
    @State private var typingOn = false

    var body: some View {
        NavigationStack {
            Form {
                Picker("From", selection: $threadID) {
                    ForEach(profile.threads) { thread in
                        Text(thread.resolvedName(in: profile)).tag(Optional(thread.id))
                    }
                }

                Section {
                    TextField("Message text", text: $text, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section {
                    Button {
                        guard let threadID else { return }
                        typingOn.toggle()
                        session.fire(.setTyping(threadID: threadID, isTyping: typingOn))
                    } label: {
                        Label(
                            typingOn ? "Stop typing bubble" : "Show typing bubble",
                            systemImage: "ellipsis.bubble"
                        )
                    }
                    .disabled(threadID == nil)

                    Button {
                        guard let threadID, !text.isEmpty else { return }
                        session.fire(.incomingText(threadID: threadID, text: text))
                        typingOn = false
                        text = ""
                        dismiss()
                    } label: {
                        Label("Send text", systemImage: "paperplane.fill")
                            .fontWeight(.semibold)
                    }
                    .disabled(threadID == nil || text.isEmpty)
                }
            }
            .navigationTitle("Send Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                if threadID == nil { threadID = profile.threads.first?.id }
            }
        }
    }
}
