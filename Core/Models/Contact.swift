//
//  Contact.swift
//  PropPhone
//
//  Created by Claude Code
//

import Foundation

/// A contact belonging to a CharacterPhone
/// Used as the sender for calls and messages
struct Contact: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var phoneNumber: String?
    var photoData: Data?
    var iconName: String
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        phoneNumber: String? = nil,
        photoData: Data? = nil,
        iconName: String = "person.circle.fill",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.photoData = photoData
        self.iconName = iconName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Display subtitle (phone number or placeholder)
    var subtitle: String {
        phoneNumber ?? "No number"
    }
}
