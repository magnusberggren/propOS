//
//  Template.swift
//  PropPhone
//
//  Created by Claude Code
//

import Foundation

// MARK: - Call Template

struct CallTemplate: Codable, Identifiable {
    let id: UUID
    var name: String
    var callerName: String
    var callerNumber: String?
    var callerPhotoData: Data?
    var callerIcon: String
    var isVideo: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        callerName: String,
        callerNumber: String? = nil,
        callerPhotoData: Data? = nil,
        callerIcon: String = "person.circle.fill",
        isVideo: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.callerName = callerName
        self.callerNumber = callerNumber
        self.callerPhotoData = callerPhotoData
        self.callerIcon = callerIcon
        self.isVideo = isVideo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Creates a CallState from this template
    func toCallState() -> CallState {
        CallState(
            callerName: callerName,
            callerNumber: callerNumber,
            callerPhotoURL: callerIcon,
            isVideo: isVideo
        )
    }
}

// MARK: - Notification Template

struct NotificationTemplate: Codable, Identifiable {
    let id: UUID
    var name: String
    var appName: String
    var appIcon: String
    var title: String
    var body: String
    var isUrgent: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        appName: String,
        appIcon: String = "app.fill",
        title: String,
        body: String,
        isUrgent: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.appName = appName
        self.appIcon = appIcon
        self.title = title
        self.body = body
        self.isUrgent = isUrgent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Creates a PropNotification from this template
    func toNotification() -> PropNotification {
        PropNotification(
            appName: appName,
            appIcon: appIcon,
            title: title,
            body: body,
            isUrgent: isUrgent
        )
    }
}

// MARK: - Lock Screen Scene Template

/// A lock screen base state - date/time and wallpaper setup for a scene
/// Notifications are sent dynamically via the controller during filming
struct LockScreenTemplate: Codable, Identifiable {
    let id: UUID
    var name: String
    var displayTime: Date
    var wallpaperName: String  // Wallpaper.rawValue or "custom"
    var wallpaperImageData: Data?  // For custom wallpaper
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        displayTime: Date,
        wallpaperName: String,
        wallpaperImageData: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.displayTime = displayTime
        self.wallpaperName = wallpaperName
        self.wallpaperImageData = wallpaperImageData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

