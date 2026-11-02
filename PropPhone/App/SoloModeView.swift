//
//  SoloModeView.swift
//  PropPhone
//
//  Phone and controls on one device: the renderer runs full screen,
//  and a hidden triple-tap corner opens the operator panel with
//  scene RESET and cue firing. Built for single-phone scenes like
//  "she listens to her voicemails" — reset a take in one tap.
//

import SwiftUI

struct SoloModeView: View {
    @Environment(ShowStore.self) private var store
    @AppStorage("appRole") private var roleRaw = ""

    @State private var runtime: PhoneRuntime?
    @State private var selectedSceneID: UUID?
    @State private var showPanel = false

    var body: some View {
        ZStack {
            if let runtime {
                // Keyboard region stays active so the Messages input bar
                // rises with the real keyboard.
                PhoneScreenView(runtime: runtime)
                    .ignoresSafeArea(.container)
                    .calibrationOverlay()
            } else {
                Color.black.ignoresSafeArea()
            }

            // Hidden operator escape: long-press the top-right corner
            // (top-left would cover the Back buttons of the fake apps).
            VStack {
                HStack {
                    Spacer()
                    Color.clear
                        .frame(width: 70, height: 70)
                        .contentShape(Rectangle())
                        .onLongPressGesture(minimumDuration: 1.0) { showPanel = true }
                }
                Spacer()
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .sheet(isPresented: $showPanel) {
            SoloOperatorPanel(
                runtime: runtime,
                selectedSceneID: $selectedSceneID,
                onLoadScene: loadScene,
                onExit: { roleRaw = AppRole.none.rawValue }
            )
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            if runtime == nil {
                selectedSceneID = selectedSceneID ?? store.document.scenes.first?.id
                loadScene()
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func loadScene() {
        let baseline: PhoneState
        if let scene = store.document.scenes.first(where: { $0.id == selectedSceneID }) {
            baseline = scene.baseline
        } else if let phone = store.document.phones.first {
            baseline = PhoneState(profile: phone)
        } else {
            baseline = PhoneState(profile: PhoneProfile(name: "Empty"))
        }
        if let runtime {
            runtime.applyExternal(baseline)
        } else {
            runtime = PhoneRuntime(state: baseline)
        }
    }
}

// MARK: - Operator panel

struct SoloOperatorPanel: View {
    let runtime: PhoneRuntime?
    @Binding var selectedSceneID: UUID?
    var onLoadScene: () -> Void
    var onExit: () -> Void

    @Environment(ShowStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("calibrationOverlayEnabled") private var calibrationEnabled = false
    @AppStorage("calibrationOverlayOpacity") private var calibrationOpacity = 0.5

    var body: some View {
        NavigationStack {
            List {
                Section("Scene") {
                    Picker("Scene", selection: $selectedSceneID) {
                        ForEach(store.document.scenes) { scene in
                            Text(scene.name).tag(Optional(scene.id))
                        }
                    }
                    .onChange(of: selectedSceneID) { _, _ in
                        onLoadScene()
                    }

                    Button {
                        onLoadScene()
                        dismiss()
                    } label: {
                        Label("RESET to top of scene", systemImage: "arrow.counterclockwise")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }

                if let scene = store.document.scenes.first(where: { $0.id == selectedSceneID }),
                   let runtime {
                    Section("Cues") {
                        ForEach(scene.cues) { cue in
                            Button {
                                runtime.perform(cue.action)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(cue.name)
                                    Spacer()
                                    Text("GO")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(Color.green, in: Capsule())
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Section("Screen") {
                        Button("Lock screen") { runtime.perform(.setScreen(.lockScreen)); dismiss() }
                        Button("Home screen") { runtime.perform(.setScreen(.home)); dismiss() }
                        Button("Voicemail") {
                            runtime.perform(.setScreen(.phoneApp(PhoneAppState(tab: .voicemail))))
                            dismiss()
                        }
                        Button("Messages") {
                            runtime.perform(.setScreen(.messagesApp(MessagesAppState())))
                            dismiss()
                        }
                        Button("Photos") {
                            runtime.perform(.setScreen(.photosApp(PhotosAppState())))
                            dismiss()
                        }
                        Button(runtime.state.blackout ? "Screen on" : "Screen black") {
                            runtime.perform(.blackout(!runtime.state.blackout))
                            dismiss()
                        }
                    }
                }

                #if DEBUG
                Section("Calibration") {
                    Toggle("Reference overlay", isOn: $calibrationEnabled)
                    if calibrationEnabled {
                        Slider(value: $calibrationOpacity, in: 0.1...0.9)
                    }
                }
                #endif

                Section {
                    Button("Exit solo mode", role: .destructive) {
                        dismiss()
                        onExit()
                    }
                }
            }
            .navigationTitle("Operator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
