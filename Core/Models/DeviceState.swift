//
//  DeviceState.swift
//  PropPhone
//
//  Created by Claude Code
//

import Foundation

/// Represents the complete state of a Mimic device
/// This state is synchronized between Controller and Mimic
struct DeviceState: Codable, Equatable {
    var mode: MimicDisplayMode
    var currentCall: CallState?
    var notifications: [PropNotification]
    var displayTime: Date       // The time to display (can be frozen)
    var freezeTime: Bool        // If true, time doesn't advance
    var screenBlackout: Bool    // If true, screen shows black (proximity sensor simulation)

    // Phone config (from CharacterPhone)
    var wallpaperName: String?
    var wallpaperImageData: Data?
    var batteryPercent: Int
    var signalStrength: Int
    var carrierName: String

    init(
        mode: MimicDisplayMode = .idle,
        currentCall: CallState? = nil,
        notifications: [PropNotification] = [],
        displayTime: Date = Date(),
        freezeTime: Bool = false,
        screenBlackout: Bool = false,
        wallpaperName: String? = nil,
        wallpaperImageData: Data? = nil,
        batteryPercent: Int = 85,
        signalStrength: Int = 4,
        carrierName: String = "Carrier"
    ) {
        self.mode = mode
        self.currentCall = currentCall
        self.notifications = notifications
        self.displayTime = displayTime
        self.freezeTime = freezeTime
        self.screenBlackout = screenBlackout
        self.wallpaperName = wallpaperName
        self.wallpaperImageData = wallpaperImageData
        self.batteryPercent = batteryPercent
        self.signalStrength = signalStrength
        self.carrierName = carrierName
    }

    /// Apply phone config to device state
    mutating func applyPhoneConfig(_ config: PhoneConfig) {
        wallpaperName = config.wallpaperName
        wallpaperImageData = config.wallpaperImageData
        carrierName = config.carrierName
        signalStrength = config.signalStrength
        batteryPercent = config.batteryPercent
    }

    /// Default state for a new Mimic device
    static var initial: DeviceState {
        DeviceState(
            mode: .idle,
            displayTime: Date(),
            freezeTime: false,
            screenBlackout: false
        )
    }
}
