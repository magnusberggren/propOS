//
//  PhoneModeView.swift
//  PropPhone
//
//  Prop-phone role: full-screen renderer driven by the controller.
//  A hidden triple-tap zone in the top-left corner opens the crew
//  drawer (connection info, calibration, exit) without giving the
//  actor anything to accidentally trigger.
//

import SwiftUI

struct PhoneModeView: View {
    @Environment(ShowStore.self) private var store
    @AppStorage("appRole") private var roleRaw = ""

    @State private var session: PhoneSession?
    @State private var showDrawer = false
    @State private var hideConnectionChip = false

    var body: some View {
        ZStack {
            if let session {
                // Keyboard region stays active so the Messages input bar
                // rises with the real keyboard.
                PhoneScreenView(runtime: session.runtime)
                    .ignoresSafeArea(.container)
                    .calibrationOverlay()

                if !session.isConnected && !hideConnectionChip {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            ProgressView().tint(.white)
                            Text("Waiting for controller")
                                .font(.footnote)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.6), in: Capsule())
                        .padding(.bottom, 60)
                        .onTapGesture { hideConnectionChip = true }
                    }
                    .transition(.opacity)
                }
            }

            // Hidden crew escape: long-press the top-right corner
            // (top-left would cover the Back buttons of the fake apps).
            VStack {
                HStack {
                    Spacer()
                    Color.clear
                        .frame(width: 70, height: 70)
                        .contentShape(Rectangle())
                        .onLongPressGesture(minimumDuration: 1.0) { showDrawer = true }
                }
                Spacer()
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .sheet(isPresented: $showDrawer) {
            PhoneModeDrawer(session: session) {
                roleRaw = AppRole.none.rawValue
            }
            .presentationDetents([.medium])
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            if session == nil {
                let baseline = store.document.scenes.first?.baseline
                    ?? PhoneState(profile: store.document.phones.first ?? PhoneProfile(name: "Empty"))
                let s = PhoneSession(initialState: baseline)
                s.start()
                session = s
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            session?.stop()
            session = nil
        }
    }
}

struct PhoneModeDrawer: View {
    let session: PhoneSession?
    var onExit: () -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("calibrationOverlayEnabled") private var calibrationEnabled = false
    @AppStorage("calibrationOverlayOpacity") private var calibrationOpacity = 0.5

    var body: some View {
        NavigationStack {
            List {
                Section("Connection") {
                    LabeledContent("Status") {
                        if session?.isConnected == true {
                            Label("Connected", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Label("Waiting", systemImage: "antenna.radiowaves.left.and.right")
                                .foregroundStyle(.orange)
                        }
                    }
                    if let name = session?.controllerName {
                        LabeledContent("Controller", value: name)
                    }
                }

                #if DEBUG
                Section("Calibration") {
                    Toggle("Reference overlay", isOn: $calibrationEnabled)
                    if calibrationEnabled {
                        Slider(value: $calibrationOpacity, in: 0.1...0.9) {
                            Text("Opacity")
                        }
                    }
                }
                #endif

                Section {
                    Button("Exit phone mode", role: .destructive) {
                        dismiss()
                        onExit()
                    }
                }
            }
            .navigationTitle("Crew")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
