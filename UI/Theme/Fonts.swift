
//
//  Fonts.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

/// iOS system fonts for pixel-perfect fidelity
extension Font {
    // MARK: - SF Pro Display (for large text)

    static func sfProDisplay(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    // MARK: - SF Pro Text (for body text)

    static func sfProText(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    // MARK: - Lock Screen Fonts

    static let lockScreenTime = Font.system(size: 80, weight: .thin, design: .default)
    static let lockScreenDate = Font.system(size: 18, weight: .semibold, design: .default)

    // MARK: - Call Screen Fonts

    static let callScreenCallerName = Font.system(size: 36, weight: .regular, design: .default)
    static let callScreenSubtitle = Font.system(size: 20, weight: .regular, design: .default)
    static let callScreenLabel = Font.system(size: 13, weight: .regular, design: .default)

    // MARK: - Notification Fonts

    static let notificationAppName = Font.system(size: 12, weight: .semibold, design: .default)
    static let notificationTime = Font.system(size: 12, weight: .regular, design: .default)
    static let notificationTitle = Font.system(size: 14, weight: .semibold, design: .default)
    static let notificationBody = Font.system(size: 14, weight: .regular, design: .default)

    // MARK: - Status Bar Font

    static let statusBar = Font.system(size: 14, weight: .semibold, design: .default)
}
