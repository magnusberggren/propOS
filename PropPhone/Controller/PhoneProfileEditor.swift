//
//  PhoneProfileEditor.swift
//  PropPhone
//
//  Authoring a character's phone: identity, appearance, contacts,
//  voicemail box, recents, and the scenes built on top of it.
//

import PhotosUI
import SwiftUI

struct PhoneProfileEditor: View {
    @Environment(ShowStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State var phone: PhoneProfile
    @State private var newSceneName = ""
    @State private var wallpaperItem: PhotosPickerItem?
    @State private var photoItems: [PhotosPickerItem] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Phone") {
                    TextField("Name", text: $phone.name)
                }

                appearanceSection
                statusBarSection

                Section("Contacts") {
                    ForEach($phone.contacts) { $contact in
                        NavigationLink {
                            ContactEditor(contact: $contact, favorites: $phone.favorites)
                        } label: {
                            HStack {
                                AvatarView(
                                    name: contact.displayName,
                                    monogram: contact.monogram,
                                    imageAsset: contact.imageAsset,
                                    size: 32
                                )
                                Text(contact.displayName)
                                if phone.favorites.contains(contact.id) {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        let removed = indexSet.map { phone.contacts[$0].id }
                        phone.contacts.remove(atOffsets: indexSet)
                        phone.favorites.removeAll { removed.contains($0) }
                    }

                    Button {
                        phone.contacts.append(ContactCard(givenName: "New", familyName: "Contact"))
                    } label: {
                        Label("Add contact", systemImage: "plus")
                    }
                }

                Section("Content") {
                    NavigationLink {
                        VoicemailComposer(phone: $phone)
                    } label: {
                        HStack {
                            Label("Voicemails", systemImage: "recordingtape")
                            Spacer()
                            Text("\(phone.voicemails.count)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        ThreadComposer(phone: $phone)
                    } label: {
                        HStack {
                            Label("Message threads", systemImage: "message")
                            Spacer()
                            Text("\(phone.threads.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                photosSection

                scenesSection
            }
            .navigationTitle("Edit Phone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.upsertPhone(phone)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("Wallpaper") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(1...10, id: \.self) { i in
                        let name = "Wallpaper\(i)"
                        Button {
                            phone.wallpaper = .builtin(name)
                        } label: {
                            wallpaperThumb(name: name)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }

            PhotosPicker(selection: $wallpaperItem, matching: .images) {
                Label("Custom wallpaper from Photos", systemImage: "photo")
            }
            .onChange(of: wallpaperItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data),
                       let ref = try? AssetStore.shared.storeImage(image) {
                        phone.wallpaper = .asset(ref)
                    }
                }
            }
        }
    }

    private func wallpaperThumb(name: String) -> some View {
        let isSelected: Bool = {
            if case .builtin(let n) = phone.wallpaper { return n == name }
            return false
        }()
        return Group {
            if UIImage(named: name) != nil {
                Image(name).resizable().aspectRatio(contentMode: .fill)
            } else {
                Color.gray
            }
        }
        .frame(width: 44, height: 92)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 3)
        }
    }

    // MARK: - Photos library

    private var photosSection: some View {
        Section("Photos library (\(phone.photos.count))") {
            if !phone.photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(phone.photos.enumerated()), id: \.offset) { index, spec in
                            SpecImage(spec: spec)
                                .aspectRatio(1, contentMode: .fill)
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        phone.photos.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white, .black.opacity(0.55))
                                    }
                                    .buttonStyle(.plain)
                                    .padding(2)
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            PhotosPicker(selection: $photoItems, maxSelectionCount: 30, matching: .images) {
                Label("Add photos from library", systemImage: "photo.badge.plus")
            }
            .onChange(of: photoItems) { _, items in
                guard !items.isEmpty else { return }
                Task {
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data),
                           let ref = try? AssetStore.shared.storeImage(image) {
                            phone.photos.insert(.asset(ref), at: 0)
                        }
                    }
                    photoItems = []
                }
            }
        }
    }

    // MARK: - Status bar

    private var statusBarSection: some View {
        Section("Status bar") {
            TextField("Carrier", text: $phone.statusBar.carrierName)

            Stepper("Signal: \(phone.statusBar.signalBars) bars", value: $phone.statusBar.signalBars, in: 0...4)

            Toggle("Wi-Fi indicator", isOn: $phone.statusBar.showWiFi)

            VStack(alignment: .leading) {
                Text("Battery: \(phone.statusBar.batteryPercent)%")
                Slider(
                    value: Binding(
                        get: { Double(phone.statusBar.batteryPercent) },
                        set: { phone.statusBar.batteryPercent = Int($0) }
                    ),
                    in: 1...100, step: 1
                )
            }

            Toggle("Show battery percent", isOn: $phone.statusBar.showBatteryPercent)
        }
    }

    // MARK: - Scenes

    private var scenesSection: some View {
        Section("Scenes using this phone") {
            ForEach(store.document.scenes.filter { $0.phoneID == phone.id }) { scene in
                Text(scene.name)
            }

            HStack {
                TextField("New scene name", text: $newSceneName)
                Button("Add") {
                    var baseline = PhoneState(profile: phone)
                    baseline.screen = .lockScreen
                    let scene = SceneSetup(
                        name: newSceneName.isEmpty ? "Scene" : newSceneName,
                        phoneID: phone.id,
                        baseline: baseline
                    )
                    store.upsertScene(scene)
                    newSceneName = ""
                }
                .disabled(newSceneName.isEmpty)
            }
        }
    }
}

// MARK: - Contact editor

struct ContactEditor: View {
    @Binding var contact: ContactCard
    @Binding var favorites: [UUID]

    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        Form {
            Section {
                TextField("First name", text: $contact.givenName)
                TextField("Last name", text: $contact.familyName)
                TextField("Phone number", text: $contact.phoneNumber)
                TextField("Label (mobile, work…)", text: $contact.numberLabel)
            }

            Section("Photo") {
                HStack {
                    AvatarView(
                        name: contact.displayName,
                        monogram: contact.monogram,
                        imageAsset: contact.imageAsset,
                        size: 56
                    )
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Text(contact.imageAsset == nil ? "Add photo" : "Change photo")
                    }
                    if contact.imageAsset != nil {
                        Button("Remove", role: .destructive) {
                            contact.imageAsset = nil
                        }
                    }
                }
                .onChange(of: photoItem) { _, item in
                    guard let item else { return }
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data),
                           let ref = try? AssetStore.shared.storeImage(image) {
                            contact.imageAsset = ref
                        }
                    }
                }
            }

            Section {
                Toggle("Favorite", isOn: Binding(
                    get: { favorites.contains(contact.id) },
                    set: { on in
                        if on {
                            if !favorites.contains(contact.id) { favorites.append(contact.id) }
                        } else {
                            favorites.removeAll { $0 == contact.id }
                        }
                    }
                ))
            }
        }
        .navigationTitle(contact.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
