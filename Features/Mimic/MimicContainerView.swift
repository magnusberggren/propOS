//
//  MimicContainerView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

struct MimicContainerView: View {
    @Environment(MimicViewModel.self) private var mimicVM
    @Environment(AppViewModel.self) private var appViewModel
    @State private var showExitConfirmation = false

    var body: some View {
        ZStack {
            // Priority 1: Screen blackout (proximity sensor simulation)
            if mimicVM.deviceState.screenBlackout {
                ProximityBlackoutView()
            }
            // Priority 2: Display appropriate screen based on mode
            else if mimicVM.shouldShowCallScreen {
                IncomingCallView(call: mimicVM.deviceState.currentCall!)
            } else if mimicVM.shouldShowLockScreen {
                LockScreenView(
                    time: mimicVM.currentDisplayTime,
                    notifications: mimicVM.deviceState.notifications,
                    signalStrength: mimicVM.deviceState.signalStrength,
                    carrierName: mimicVM.deviceState.carrierName,
                    batteryPercent: mimicVM.deviceState.batteryPercent
                )
            } else {
                // Idle state - black screen like phone is off
                IdleView()
            }
        }
        .statusBarHidden(true) // Hide real status bar
        .ignoresSafeArea()
        .gesture(
            // Secret exit gesture: 3-finger triple-tap
            TapGesture(count: 3)
                .simultaneously(with: TapGesture(count: 3))
                .onEnded { _ in
                    showExitConfirmation = true
                }
        )
        .alert("Exit Mimic Mode?", isPresented: $showExitConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Exit", role: .destructive) {
                appViewModel.returnToModeSelection()
            }
        } message: {
            Text("Return to mode selection?")
        }
    }
}

/// Completely black screen - simulates phone with screen off
struct IdleView: View {
    var body: some View {
        Color.black
            .ignoresSafeArea()
    }
}

/// Black screen for proximity sensor simulation during calls
struct ProximityBlackoutView: View {
    var body: some View {
        Color.black
            .ignoresSafeArea()
    }
}

#Preview {
    MimicContainerView()
        .environment(MimicViewModel(multipeerService: MultipeerService(mode: .mimic)))
        .environment(AppViewModel())
}
