//
//  MimicViewModel.swift
//  PropPhone
//
//  Created by Claude Code
//

import Foundation
import UIKit
import MultipeerConnectivity

/// ViewModel for Mimic mode - receives commands and manages display state
@Observable
class MimicViewModel {
    let multipeerService: MultipeerService
    var deviceState: DeviceState
    var currentDisplayTime: Date

    // Timer for updating time if not frozen
    private var timeUpdateTimer: Timer?

    init(multipeerService: MultipeerService) {
        self.multipeerService = multipeerService
        self.deviceState = DeviceState.initial
        self.currentDisplayTime = Date()

        // Listen for incoming messages
        multipeerService.onMessageReceived = { [weak self] message, peer in
            self?.handleMessage(message, from: peer)
        }

        // Start time update timer
        startTimeUpdater()

        // Prevent screen from sleeping
        UIApplication.shared.isIdleTimerDisabled = true
    }

    deinit {
        // Re-enable screen auto-lock
        UIApplication.shared.isIdleTimerDisabled = false
        timeUpdateTimer?.invalidate()
    }

    // MARK: - Message Handling

    private func handleMessage(_ message: NetworkMessage, from peer: MCPeerID) {
        switch message {
        case .triggerCall(let call):
            deviceState.currentCall = call
            deviceState.mode = .incomingCall

        case .dismissCall:
            deviceState.currentCall = nil
            // Return to previous mode or idle
            if !deviceState.notifications.isEmpty {
                deviceState.mode = .lockScreen
            } else {
                deviceState.mode = .idle
            }

        case .addNotification(let notification):
            deviceState.notifications.append(notification)
            // Switch to lock screen if not showing call
            if deviceState.mode != .incomingCall {
                deviceState.mode = .lockScreen
            }

        case .removeNotification(let id):
            deviceState.notifications.removeAll { $0.id == id }
            // If no more notifications and no call, go to idle
            if deviceState.notifications.isEmpty && deviceState.mode == .lockScreen {
                deviceState.mode = .idle
            }

        case .clearAllNotifications:
            deviceState.notifications.removeAll()
            if deviceState.mode == .lockScreen {
                deviceState.mode = .idle
            }

        case .updateTime(let time, let freeze):
            deviceState.displayTime = time
            currentDisplayTime = time
            deviceState.freezeTime = freeze

        case .syncCurrentTime:
            let now = Date()
            deviceState.displayTime = now
            currentDisplayTime = now
            deviceState.freezeTime = false

        case .switchToLockScreen:
            deviceState.mode = .lockScreen

        case .switchToIdle:
            deviceState.mode = .idle

        case .setScreenBlackout(let blackout):
            deviceState.screenBlackout = blackout

        case .loadPhoneConfig(let config):
            deviceState.applyPhoneConfig(config)

        case .requestFullState:
            // Send back our current state
            let response = NetworkMessage.fullStateUpdate(deviceState)
            multipeerService.send(response, to: [peer])

        case .fullStateUpdate(let state):
            // Update our state from controller
            deviceState = state
            currentDisplayTime = state.displayTime

        case .ping:
            // Respond with pong
            multipeerService.send(.pong, to: [peer])

        case .pong:
            // Connection health check received
            break
        }
    }

    // MARK: - Time Management

    private func startTimeUpdater() {
        timeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTime()
        }
    }

    private func updateTime() {
        guard !deviceState.freezeTime else { return }
        // Advance display time by 1 second
        currentDisplayTime = currentDisplayTime.addingTimeInterval(1)
        deviceState.displayTime = currentDisplayTime
    }

    // MARK: - Display Helpers

    var shouldShowCallScreen: Bool {
        deviceState.mode == .incomingCall && deviceState.currentCall != nil
    }

    var shouldShowLockScreen: Bool {
        deviceState.mode == .lockScreen
    }

    var shouldShowIdle: Bool {
        deviceState.mode == .idle
    }
}
