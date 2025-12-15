//
//  Colors.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

/// iOS system colors for pixel-perfect fidelity
extension Color {
    // MARK: - iOS System Colors

    static let iosSystemBackground = Color(uiColor: .systemBackground)
    static let iosSecondarySystemBackground = Color(uiColor: .secondarySystemBackground)
    static let iosTertiarySystemBackground = Color(uiColor: .tertiarySystemBackground)

    static let iosLabel = Color(uiColor: .label)
    static let iosSecondaryLabel = Color(uiColor: .secondaryLabel)
    static let iosTertiaryLabel = Color(uiColor: .tertiaryLabel)
    static let iosQuaternaryLabel = Color(uiColor: .quaternaryLabel)

    static let iosSeparator = Color(uiColor: .separator)

    // MARK: - Call Screen Colors

    static let callGreen = Color(red: 0.298, green: 0.851, blue: 0.392) // iOS green button
    static let callRed = Color(red: 1.0, green: 0.231, blue: 0.188) // iOS red button

    // MARK: - Lock Screen Colors

    static let lockScreenBackground = Color.black
    static let lockScreenText = Color.white

    // MARK: - Notification Colors

    static let notificationBackground = Color(white: 0.15, opacity: 0.95)
    static let notificationUrgentBackground = Color(red: 0.9, green: 0.2, blue: 0.2, opacity: 0.95)

    // MARK: - Glassmorphism Vibrant Colors

    // Electric Cyan-Purple (Hero gradient colors)
    static let electricCyan = Color(red: 0.4, green: 0.8, blue: 1.0)      // #66CCFF
    static let vibrantPurple = Color(red: 0.6, green: 0.4, blue: 1.0)     // #9966FF
    static let hotMagenta = Color(red: 0.8, green: 0.3, blue: 1.0)        // #CC4DFF

    // Neon Teal-Blue (Accent gradient colors)
    static let neonTeal = Color(red: 0.2, green: 0.9, blue: 0.9)          // #33E6E6
    static let skyBlue = Color(red: 0.3, green: 0.6, blue: 1.0)           // #4D99FF
    static let brightCyan = Color(red: 0.4, green: 0.8, blue: 1.0)        // #66CCFF

    // Sunset Pink-Orange (Warm gradient colors)
    static let hotPink = Color(red: 1.0, green: 0.4, blue: 0.6)           // #FF6699
    static let coral = Color(red: 1.0, green: 0.6, blue: 0.3)             // #FF994D
    static let golden = Color(red: 1.0, green: 0.8, blue: 0.4)            // #FFCC66

    // Aurora Green-Blue (Cool gradient colors)
    static let mint = Color(red: 0.3, green: 1.0, blue: 0.7)              // #4DFFB3
    static let aqua = Color(red: 0.4, green: 0.9, blue: 1.0)              // #66E6FF
    static let periwinkle = Color(red: 0.5, green: 0.6, blue: 1.0)        // #8099FF

    // MARK: - Glass Tints

    // Light glass tints (for light backgrounds)
    static let glassTintLight = Color.white.opacity(0.15)
    static let glassTintSubtle = Color.white.opacity(0.08)
    static let glassTintUltraSubtle = Color.white.opacity(0.03)

    // Dark glass tints (for dark backgrounds)
    static let glassTintFrosted = Color.white.opacity(0.12)
    static let glassTintSemiFrosted = Color.white.opacity(0.06)
    static let glassTintDark = Color(white: 0.2, opacity: 0.4)

    // MARK: - Cosmic Background Colors

    // Deep space gradient colors
    static let deepNavy = Color(red: 0.05, green: 0.1, blue: 0.25)
    static let richPurple = Color(red: 0.15, green: 0.05, blue: 0.3)
    static let deepBlue = Color(red: 0.0, green: 0.05, blue: 0.2)

    // Rich gradient backgrounds for edit screens
    static let darkNavy = Color(red: 0.08, green: 0.1, blue: 0.15)
    static let darkerNavy = Color(red: 0.05, green: 0.06, blue: 0.1)
}
