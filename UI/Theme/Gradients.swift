//
//  Gradients.swift
//  PropPhone
//
//  Vibrant gradient library for glassmorphism design
//

import SwiftUI

// MARK: - Gradient Library

struct AppGradients {

    // MARK: - Primary Gradients

    /// Electric Cyan → Purple → Magenta (Hero gradient)
    static let electricPurple = LinearGradient(
        colors: [.electricCyan, .vibrantPurple, .hotMagenta],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Neon Teal → Sky Blue → Bright Cyan (Accent gradient)
    static let neonBlue = LinearGradient(
        colors: [.neonTeal, .skyBlue, .brightCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Hot Pink → Coral → Golden (Warm gradient)
    static let sunsetWarm = LinearGradient(
        colors: [.hotPink, .coral, .golden],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Mint → Aqua → Periwinkle (Cool gradient)
    static let auroraCool = LinearGradient(
        colors: [.mint, .aqua, .periwinkle],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Background Gradients

    /// Deep cosmic gradient for main backgrounds
    static let cosmicBackground = LinearGradient(
        colors: [.deepNavy, .richPurple, .deepBlue],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Rich dark gradient for edit screens
    static let darkBackground = LinearGradient(
        colors: [.darkNavy, .darkerNavy],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Button Gradients

    /// Success/Accept button gradient (green)
    static let successButton = LinearGradient(
        colors: [
            Color(red: 0.3, green: 0.95, blue: 0.5),   // Bright green
            Color(red: 0.2, green: 0.85, blue: 0.4)    // Rich green
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Error/Decline button gradient (red)
    static let errorButton = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.3, blue: 0.3),    // Bright red
            Color(red: 0.9, green: 0.2, blue: 0.2)     // Deep red
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Primary action button gradient (blue-purple)
    static let primaryButton = LinearGradient(
        colors: [
            Color(red: 0.0, green: 0.48, blue: 1.0),   // Bright blue
            Color(red: 0.35, green: 0.34, blue: 0.84)  // Purple blue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Preview/Play button gradient (green-cyan)
    static let previewButton = LinearGradient(
        colors: [
            Color(red: 0.2, green: 0.78, blue: 0.35),  // Bright green
            Color(red: 0.15, green: 0.68, blue: 0.30)  // Rich green
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Icon Badge Gradients

    /// Vibrant icon gradient (purple-blue-cyan)
    static let iconBadge = LinearGradient(
        colors: [.vibrantPurple, .skyBlue, .electricCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Warm icon gradient (pink-coral)
    static let iconBadgeWarm = LinearGradient(
        colors: [.hotPink, .coral],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Cool icon gradient (teal-aqua)
    static let iconBadgeCool = LinearGradient(
        colors: [.neonTeal, .aqua],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Glass Overlay Gradients

    /// Subtle glass overlay for backgrounds
    static let glassOverlay = LinearGradient(
        colors: [
            Color.white.opacity(0.1),
            Color.white.opacity(0.05),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Shimmer border gradient
    static let shimmerBorder = LinearGradient(
        colors: [
            Color.white.opacity(0.6),
            Color.white.opacity(0.3),
            Color.white.opacity(0.1),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle border gradient
    static let subtleBorder = LinearGradient(
        colors: [
            Color.white.opacity(0.2),
            Color.white.opacity(0.1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Radial Gradients

    /// Radial glow for glass orbs
    static func radialGlow(centerColor: Color, edgeColor: Color = .clear) -> RadialGradient {
        RadialGradient(
            colors: [centerColor, edgeColor],
            center: .center,
            startRadius: 0,
            endRadius: 100
        )
    }

    /// Spotlight effect
    static let spotlight = RadialGradient(
        colors: [
            Color.white.opacity(0.2),
            Color.white.opacity(0.1),
            Color.clear
        ],
        center: .top,
        startRadius: 0,
        endRadius: 300
    )
}

// MARK: - Contextual Gradients Extension

extension AppGradients {

    /// Get gradient by category
    static func forCategory(_ category: String) -> LinearGradient {
        switch category.lowercased() {
        case "personal":
            return neonBlue
        case "business":
            return primaryButton
        case "emergency":
            return errorButton
        case "entertainment":
            return sunsetWarm
        case "social":
            return electricPurple
        default:
            return auroraCool
        }
    }

    /// Get gradient by state
    static func forState(_ state: String) -> LinearGradient {
        switch state.lowercased() {
        case "success", "accept":
            return successButton
        case "error", "decline", "delete":
            return errorButton
        case "info", "default":
            return primaryButton
        case "preview", "play":
            return previewButton
        default:
            return electricPurple
        }
    }
}

// MARK: - Animated Gradient Modifier

struct AnimatedGradientModifier: ViewModifier {
    @State private var animateGradient = false

    let colors: [Color]
    let startPoint: UnitPoint
    let endPoint: UnitPoint

    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: animateGradient ? endPoint : startPoint,
                    endPoint: animateGradient ? startPoint : endPoint
                )
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
    }
}

extension View {
    /// Animated gradient background
    func animatedGradient(
        colors: [Color],
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) -> some View {
        self.modifier(AnimatedGradientModifier(
            colors: colors,
            startPoint: startPoint,
            endPoint: endPoint
        ))
    }
}
