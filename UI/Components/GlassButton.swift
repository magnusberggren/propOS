//
//  GlassButton.swift
//  PropPhone
//
//  Reusable glass button component with glassmorphism effects
//

import SwiftUI

// MARK: - Glass Button

struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    var style: GlassButtonStyle = .primary
    var size: GlassButtonSize = .medium
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: size.iconSpacing) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: size.fontSize, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: size.maxWidth)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                ZStack {
                    // Blur layer
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .fill(.ultraThinMaterial)

                    // Gradient overlay
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .fill(style.gradient)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
            .shadow(color: style.glowColor, radius: style.glowRadius, x: 0, y: 0)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

// MARK: - Glass Button Style

enum GlassButtonStyle {
    case primary
    case success
    case error
    case warning
    case info
    case custom(gradient: LinearGradient, glow: Color)

    var gradient: LinearGradient {
        switch self {
        case .primary:
            return AppGradients.primaryButton
        case .success:
            return AppGradients.successButton
        case .error:
            return AppGradients.errorButton
        case .warning:
            return AppGradients.sunsetWarm
        case .info:
            return AppGradients.neonBlue
        case .custom(let gradient, _):
            return gradient
        }
    }

    var glowColor: Color {
        switch self {
        case .primary:
            return GlowColors.info
        case .success:
            return GlowColors.success
        case .error:
            return GlowColors.error
        case .warning:
            return GlowColors.warning
        case .info:
            return GlowColors.cyan
        case .custom(_, let glow):
            return glow
        }
    }

    var glowRadius: CGFloat {
        switch self {
        case .primary, .info:
            return 20
        case .success, .error:
            return 25
        case .warning:
            return 18
        case .custom:
            return 20
        }
    }
}

// MARK: - Glass Button Size

enum GlassButtonSize {
    case small
    case medium
    case large

    var fontSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 17
        case .large: return 19
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        }
    }

    var iconSpacing: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 10
        case .large: return 12
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 16
        case .large: return 20
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 24
        case .large: return 32
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 14
        case .large: return 16
        }
    }

    var maxWidth: CGFloat? {
        switch self {
        case .small: return nil
        case .medium, .large: return .infinity
        }
    }
}

// MARK: - Icon-Only Glass Button

struct GlassIconButton: View {
    let icon: String
    let action: () -> Void

    var style: GlassButtonStyle = .primary
    var size: CGFloat = 50
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Glass background
                Circle()
                    .fill(.ultraThinMaterial)

                // Gradient overlay
                Circle()
                    .fill(style.gradient.opacity(0.3))

                // Icon
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            .shadow(color: style.glowColor, radius: style.glowRadius, x: 0, y: 0)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

// MARK: - Preview

#Preview("Glass Buttons") {
    ZStack {
        LinearGradient(
            colors: [Color.black, Color(red: 0.1, green: 0.05, blue: 0.2)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 20) {
            GlassButton(
                title: "Primary Button",
                icon: "star.fill",
                action: {},
                style: .primary,
                size: .large
            )

            GlassButton(
                title: "Success",
                icon: "checkmark.circle.fill",
                action: {},
                style: .success,
                size: .medium
            )

            GlassButton(
                title: "Error",
                icon: "xmark.circle.fill",
                action: {},
                style: .error,
                size: .medium
            )

            HStack(spacing: 20) {
                GlassIconButton(icon: "phone.fill", action: {}, style: .success)
                GlassIconButton(icon: "xmark", action: {}, style: .error)
                GlassIconButton(icon: "message.fill", action: {}, style: .info, size: 60)
            }

            GlassButton(
                title: "Small Button",
                icon: nil,
                action: {},
                style: .info,
                size: .small
            )
        }
        .padding()
    }
}
