//
//  NetworkMessage.swift
//  PropPhone
//
//  Created by Claude Code
//

import Foundation

/// Defines all messages that can be sent between Controller and Mimic devices
enum NetworkMessage: Codable {
    // Call control
    case triggerCall(CallState)
    case dismissCall

    // Notification control
    case addNotification(PropNotification)
    case removeNotification(UUID)
    case clearAllNotifications

    // Time control
    case updateTime(Date, freeze: Bool)
    case syncCurrentTime

    // Display mode control
    case switchToLockScreen
    case switchToIdle
    case setScreenBlackout(Bool)  // Proximity sensor simulation

    // Phone configuration
    case loadPhoneConfig(PhoneConfig)

    // Device state sync
    case requestFullState
    case fullStateUpdate(DeviceState)

    // Connection health
    case ping
    case pong

    /// Encode message to JSON Data
    func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    /// Decode message from JSON Data
    static func decode(from data: Data) throws -> NetworkMessage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(NetworkMessage.self, from: data)
    }
}
