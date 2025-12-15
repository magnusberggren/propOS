//
//  GlassCard.swift
//  PropPhone
//
//  Reusable glass card component with glassmorphism effects
//

import SwiftUI

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: Content

    var glassIntensity: GlassIntensity = .medium
    var gradientOverlay: LinearGradient? = nil
    var glowColor: Color? = nil
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 24

    init(
        glassIntensity: GlassIntensity = .medium,
        gradientOverlay: LinearGradient? = nil,
        glowColor: Color? = nil,
        cornerRadius: CGFloat = 24,
        padding: CGFloat = 24,
        @ViewBuilder content: () -> Content
    ) {
        self.glassIntensity = glassIntensity
        self.gradientOverlay = gradientOverlay
        self.glowColor = glowColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Blur layer
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(glassIntensity.material)

                    // Tint overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(glassIntensity.tint)

                    // Optional gradient overlay
                    if let gradient = gradientOverlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(gradient.opacity(0.2))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        glassIntensity.borderGradient,
                        lineWidth: glassIntensity.borderWidth
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
            .if(glowColor != nil) { view in
                view.shadow(color: glowColor!, radius: 25, x: 0, y: 0)
            }
    }
}

// MARK: - Glass Intensity

enum GlassIntensity {
    case light
    case medium
    case heavy

    var material: Material {
        switch self {
        case .light:
            return .regularMaterial
        case .medium:
            return .thinMaterial
        case .heavy:
            return .ultraThinMaterial
        }
    }

    var tint: Color {
        switch self {
        case .light:
            return Color.white.opacity(0.05)
        case .medium:
            return Color.white.opacity(0.08)
        case .heavy:
            return Color.white.opacity(0.12)
        }
    }

    var borderGradient: LinearGradient {
        switch self {
        case .light:
            return LinearGradient(
                colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .medium:
            return LinearGradient(
                colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .heavy:
            return LinearGradient(
                colors: [Color.white.opacity(0.4), Color.white.opacity(0.1), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .light:
            return 0.5
        case .medium:
            return 1.0
        case .heavy:
            return 1.5
        }
    }
}

// MARK: - Glass Card with Header

struct GlassCardWithHeader<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String?
    let content: Content

    var glassIntensity: GlassIntensity = .medium
    var iconGradient: LinearGradient = AppGradients.electricPurple
    var glowColor: Color? = nil

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        glassIntensity: GlassIntensity = .medium,
        iconGradient: LinearGradient = AppGradients.electricPurple,
        glowColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.glassIntensity = glassIntensity
        self.iconGradient = iconGradient
        self.glowColor = glowColor
        self.content = content()
    }

    var body: some View {
        GlassCard(
            glassIntensity: glassIntensity,
            glowColor: glowColor
        ) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(iconGradient)
                            .frame(width: 50, height: 50)

                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: glowColor ?? .clear, radius: 15, x: 0, y: 0)

                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    Spacer()
                }

                // Content
                content
            }
        }
    }
}

// MARK: - Compact Glass Card

struct CompactGlassCard: View {
    let icon: String
    let title: String
    let value: String
    let action: (() -> Void)?

    var glassIntensity: GlassIntensity = .medium
    var accentColor: Color = .electricCyan

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)

                    Circle()
                        .fill(accentColor.opacity(0.3))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accentColor)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))

                    Text(value)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                // Arrow (if tappable)
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(glassIntensity.material)

                    RoundedRectangle(cornerRadius: 16)
                        .fill(glassIntensity.tint)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(glassIntensity.borderGradient, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
        }
        .disabled(action == nil)
    }
}

// MARK: - Preview

#Preview("Glass Cards") {
    ScrollView {
        ZStack {
            AppGradients.cosmicBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Basic Glass Card
                GlassCard(glassIntensity: .heavy, glowColor: GlowColors.cyan) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Basic Glass Card")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text("This is a glass card with heavy intensity and cyan glow effect.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                // Glass Card with Header
                GlassCardWithHeader(
                    icon: "phone.fill",
                    title: "Incoming Call",
                    subtitle: "Mom",
                    glassIntensity: .heavy,
                    iconGradient: AppGradients.successButton,
                    glowColor: GlowColors.success
                ) {
                    Text("Custom content goes here...")
                        .foregroundColor(.white.opacity(0.8))
                }

                // Compact Cards
                CompactGlassCard(
                    icon: "person.fill",
                    title: "Caller",
                    value: "John Doe",
                    action: {},
                    accentColor: .vibrantPurple
                )

                CompactGlassCard(
                    icon: "bell.fill",
                    title: "Notifications",
                    value: "5 Active",
                    action: nil,
                    accentColor: .neonTeal
                )

                // Glass Card with Gradient Overlay
                GlassCard(
                    glassIntensity: .medium,
                    gradientOverlay: AppGradients.electricPurple,
                    glowColor: GlowColors.purple
                ) {
                    VStack(spacing: 12) {
                        Text("Vibrant Card")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        Text("With gradient overlay")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding()
        }
    }
}
