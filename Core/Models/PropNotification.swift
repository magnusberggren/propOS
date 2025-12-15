//
//  PropNotification.swift
//  PropPhone
//
//  Created by Claude Code
//

import Foundation

/// Represents a notification that can appear on the Mimic lock screen
struct PropNotification: Codable, Identifiable, Equatable {
    let id: UUID
    var appName: String
    var appIcon: String           // SF Symbol name or asset name
    var title: String
    var body: String
    var senderPhotoData: Data?    // Contact photo for message notifications
    var timestamp: Date
    var isUrgent: Bool            // If true, shows red/urgent style

    init(
        id: UUID = UUID(),
        appName: String,
        appIcon: String,
        title: String,
        body: String,
        senderPhotoData: Data? = nil,
        timestamp: Date = Date(),
        isUrgent: Bool = false
    ) {
        self.id = id
        self.appName = appName
        self.appIcon = appIcon
        self.title = title
        self.body = body
        self.senderPhotoData = senderPhotoData
        self.timestamp = timestamp
        self.isUrgent = isUrgent
    }

    /// Formatted time string (e.g., "now", "2m ago")
    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        }
    }

    /// Create a message notification from a Contact
    static func message(from contact: Contact, text: String, isUrgent: Bool = false) -> PropNotification {
        PropNotification(
            appName: "Messages",
            appIcon: "message.fill",
            title: contact.name,
            body: text,
            senderPhotoData: contact.photoData,
            isUrgent: isUrgent
        )
    }
}
