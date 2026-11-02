//
//  PhoneScreenView.swift
//  PropPhone
//
//  The root renderer: a pure function of PhoneRuntime.state. Every
//  surface — the actor-facing prop phone, solo mode, controller
//  mirrors, previews — renders through this one view, so what the
//  operator sees is exactly what the actor sees.
//

import SwiftUI

struct PhoneScreenView: View {
    let runtime: PhoneRuntime

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let displayTime = runtime.state.clock.displayTime(at: context.date)

            ZStack {
                Color.black.ignoresSafeArea()

                switch runtime.state.screen {
                case .off:
                    Color.black

                case .lockScreen:
                    LockScreenView(runtime: runtime, displayTime: displayTime)

                case .home:
                    HomeScreenView(runtime: runtime, displayTime: displayTime)

                case .phoneApp(let appState):
                    PhoneAppScreen(runtime: runtime, appState: appState, displayTime: displayTime)

                case .messagesApp(let appState):
                    MessagesAppScreen(runtime: runtime, appState: appState, displayTime: displayTime)

                case .photosApp(let appState):
                    PhotosAppScreen(runtime: runtime, appState: appState, displayTime: displayTime)

                case .incomingCall(let spec):
                    IncomingCallScreen(runtime: runtime, spec: spec, displayTime: displayTime)

                case .activeCall(let call):
                    ActiveCallScreen(runtime: runtime, call: call, displayTime: displayTime)
                }

                if runtime.state.blackout {
                    Color.black
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: runtime.state.screen)
        .animation(.easeInOut(duration: 0.2), value: runtime.state.blackout)
    }
}

/// Non-interactive live mirror of a phone's reported state, for the
/// controller's device roster.
struct MirrorView: View {
    let state: PhoneState

    var body: some View {
        PhoneScreenView(runtime: PhoneRuntime(state: state))
            .allowsHitTesting(false)
    }
}

// MARK: - Calibration overlay

/// DEBUG fidelity harness: drop reference screenshots into
/// Documents/Calibration/ and toggle the overlay to pixel-compare
/// our rendering against real iOS.
struct CalibrationOverlay: ViewModifier {
    @AppStorage("calibrationOverlayEnabled") private var enabled = false
    @AppStorage("calibrationOverlayOpacity") private var opacity = 0.5

    func body(content: Content) -> some View {
        content.overlay {
            #if DEBUG
            if enabled, let image = CalibrationOverlay.referenceImage() {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(opacity)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
            #endif
        }
    }

    static func referenceImage() -> UIImage? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Calibration", isDirectory: true)
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil),
              let first = files.first(where: { ["png", "jpg", "jpeg"].contains($0.pathExtension.lowercased()) })
        else { return nil }
        return UIImage(contentsOfFile: first.path)
    }
}

extension View {
    func calibrationOverlay() -> some View {
        modifier(CalibrationOverlay())
    }
}
