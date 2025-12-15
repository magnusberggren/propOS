//
//  TimeController.swift
//  PropPhone
//
//  Created by Claude Code
//

import Foundation

/// Manages time display for Mimic devices
class TimeController {
    static let shared = TimeController()

    private init() {}

    /// Format time for large lock screen display (e.g., "9:41")
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: date)
    }

    /// Format time for status bar (e.g., "9:41 AM")
    func formatTimeForStatusBar(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date).replacingOccurrences(of: " ", with: " ")
    }

    /// Format date for lock screen (e.g., "Monday, January 15")
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    /// Format full date for lock screen (e.g., "Monday, December 11")
    func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    /// Format time with seconds (e.g., "9:41:23")
    func formatTimeWithSeconds(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm:ss"
        return formatter.string(from: date)
    }

    /// Get current time adjusted for display
    func adjustedTime(from baseTime: Date, freeze: Bool) -> Date {
        if freeze {
            return baseTime
        }
        // If not frozen, calculate elapsed time since base
        return baseTime
    }
}
