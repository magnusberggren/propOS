//
//  CallState.swift
//  PropPhone
//
//  Created by Claude Code
//

import Foundation

/// Represents an incoming call that can be triggered on a Mimic device
struct CallState: Codable, Identifiable, Equatable {
    let id: UUID
    var callerName: String
    var callerNumber: String?
    var callerPhotoURL: String?  // SF Symbol name (legacy, use iconName)
    var callerPhotoData: Data?   // Actual photo data for contact
    var callerIconName: String?  // SF Symbol fallback
    var isVideo: Bool
    var timestamp: Date

    init(
        id: UUID = UUID(),
        callerName: String,
        callerNumber: String? = nil,
        callerPhotoURL: String? = nil,
        callerPhotoData: Data? = nil,
        callerIconName: String? = nil,
        isVideo: Bool = false,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.callerName = callerName
        self.callerNumber = callerNumber
        self.callerPhotoURL = callerPhotoURL
        self.callerPhotoData = callerPhotoData
        self.callerIconName = callerIconName
        self.isVideo = isVideo
        self.timestamp = timestamp
    }

    /// Display subtitle (number or "iPhone" if no number)
    var subtitle: String {
        callerNumber ?? "iPhone"
    }

    /// Create a CallState from a Contact
    static func from(contact: Contact, isVideo: Bool = false) -> CallState {
        CallState(
            callerName: contact.name,
            callerNumber: contact.phoneNumber,
            callerPhotoData: contact.photoData,
            callerIconName: contact.iconName,
            isVideo: isVideo
        )
    }
}
