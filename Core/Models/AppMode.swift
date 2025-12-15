//
//  AppMode.swift
//  PropPhone
//
//  Created by Claude Code
//

import Foundation

/// Defines the operational modes of the app
enum AppMode: String, Codable, CaseIterable {
    case controller = "Controller"
    case mimic = "Mimic"
    case demo = "Demo"

    var description: String {
        switch self {
        case .controller:
            return "Control other devices and trigger events"
        case .mimic:
            return "Display fake iPhone screens for filming"
        case .demo:
            return "Preview all screens with sample data"
        }
    }
}

/// Defines what the Mimic device is currently displaying
enum MimicDisplayMode: String, Codable {
    case idle           // Waiting for commands
    case lockScreen     // Showing lock screen
    case incomingCall   // Showing incoming call

    var displayName: String {
        switch self {
        case .idle:
            return "Idle"
        case .lockScreen:
            return "Lock Screen"
        case .incomingCall:
            return "Incoming Call"
        }
    }
}
