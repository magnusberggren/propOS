//
//  CharacterPhone.swift
//  PropPhone
//
//  Created by Claude Code
//

import Foundation

/// A complete virtual phone for a character
/// Contains contacts and phone appearance settings
struct CharacterPhone: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var contacts: [Contact]

    // Lock screen settings
    var wallpaperName: String
    var wallpaperImageData: Data?

    // Status bar customization
    var carrierName: String
    var signalStrength: Int
    var batteryPercent: Int

    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        contacts: [Contact] = [],
        wallpaperName: String = "darkBlue",
        wallpaperImageData: Data? = nil,
        carrierName: String = "Carrier",
        signalStrength: Int = 4,
        batteryPercent: Int = 85,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.contacts = contacts
        self.wallpaperName = wallpaperName
        self.wallpaperImageData = wallpaperImageData
        self.carrierName = carrierName
        self.signalStrength = signalStrength
        self.batteryPercent = batteryPercent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Default empty phone
    static var empty: CharacterPhone {
        CharacterPhone(name: "New Phone")
    }

    /// Convert to PhoneConfig for network transmission
    func toPhoneConfig() -> PhoneConfig {
        PhoneConfig(
            wallpaperName: wallpaperName,
            wallpaperImageData: wallpaperImageData,
            carrierName: carrierName,
            signalStrength: signalStrength,
            batteryPercent: batteryPercent
        )
    }
}

/// Subset of CharacterPhone sent to Mimic device
/// Contains only the display settings, not contacts
struct PhoneConfig: Codable, Equatable {
    var wallpaperName: String
    var wallpaperImageData: Data?
    var carrierName: String
    var signalStrength: Int
    var batteryPercent: Int
}
