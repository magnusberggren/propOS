//
//  Spacing.swift
//  PropPhone
//
//  Created by Claude Code
//

import Foundation

/// iOS spacing constants for pixel-perfect layout
enum Spacing {
    // MARK: - Basic Spacing

    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48

    // MARK: - Lock Screen Spacing

    static let lockScreenTopPadding: CGFloat = 60
    static let lockScreenNotificationSpacing: CGFloat = 8
    static let lockScreenTimeDateSpacing: CGFloat = 4

    // MARK: - Call Screen Spacing

    static let callScreenTopPadding: CGFloat = 100
    static let callScreenAvatarSize: CGFloat = 120
    static let callScreenButtonSpacing: CGFloat = 80
    static let callScreenBottomPadding: CGFloat = 60

    // MARK: - Notification Spacing

    static let notificationPadding: CGFloat = 12
    static let notificationCornerRadius: CGFloat = 14
    static let notificationIconSize: CGFloat = 20

    // MARK: - Button Sizing

    static let callButtonSize: CGFloat = 76
    static let smallButtonSize: CGFloat = 56
}
