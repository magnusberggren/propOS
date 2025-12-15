//
//  GlassEffects.swift
//  PropPhone
//
//  Core glassmorphism effect system
//

import SwiftUI

// MARK: - Glass Modifier

struct GlassEffect: ViewModifier {
    let blurMaterial: Material
    let tintColor: Color
    let borderGradient: LinearGradient?
    let borderWidth: CGFloat
    let glowColor: Color?
    let glowRadius: CGFloat
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Blur layer
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(blurMaterial)

                    // Tint overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(tintColor)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        borderGradient ?? LinearGradient(
                            colors: [Color.white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: borderWidth
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
            .if(glowColor != nil) { view in
                view.shadow(color: glowColor!, radius: glowRadius, x: 0, y: 0)
            }
    }
}

// MARK: - View Extension for Glass Effects

extension View {
    /// Heavy glass effect - Strong blur with prominent borders and glow
    func heavyGlass(
        tint: Color = Color.white.opacity(0.12),
        borderWidth: CGFloat = 1.5,
        glowColor: Color? = Color.cyan.opacity(0.3),
        glowRadius: CGFloat = 20,
        cornerRadius: CGFloat = 16
    ) -> some View {
        self.modifier(GlassEffect(
            blurMaterial: .ultraThinMaterial,
            tintColor: tint,
            borderGradient: shimmerBorder(),
            borderWidth: borderWidth,
            glowColor: glowColor,
            glowRadius: glowRadius,
            cornerRadius: cornerRadius
        ))
    }

    /// Medium glass effect - Balanced blur with subtle borders
    func mediumGlass(
        tint: Color = Color.white.opacity(0.08),
        borderWidth: CGFloat = 1.0,
        glowColor: Color? = Color.blue.opacity(0.2),
        glowRadius: CGFloat = 12,
        cornerRadius: CGFloat = 14
    ) -> some View {
        self.modifier(GlassEffect(
            blurMaterial: .thinMaterial,
            tintColor: tint,
            borderGradient: LinearGradient(
                colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            borderWidth: borderWidth,
            glowColor: glowColor,
            glowRadius: glowRadius,
            cornerRadius: cornerRadius
        ))
    }

    /// Light glass effect - Minimal blur with delicate appearance
    func lightGlass(
        tint: Color = Color.white.opacity(0.05),
        borderWidth: CGFloat = 0.5,
        cornerRadius: CGFloat = 12
    ) -> some View {
        self.modifier(GlassEffect(
            blurMaterial: .regularMaterial,
            tintColor: tint,
            borderGradient: LinearGradient(
                colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            ),
            borderWidth: borderWidth,
            glowColor: nil,
            glowRadius: 0,
            cornerRadius: cornerRadius
        ))
    }

    /// Vibrant glass effect - Colored tints with gradient borders
    func vibrantGlass(
        gradientTint: LinearGradient,
        borderWidth: CGFloat = 1.5,
        glowColor: Color = Color.purple.opacity(0.4),
        glowRadius: CGFloat = 25,
        cornerRadius: CGFloat = 16
    ) -> some View {
        self.background(
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(gradientTint.opacity(0.3))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(shimmerBorder(), lineWidth: borderWidth)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .shadow(color: glowColor, radius: glowRadius, x: 0, y: 0)
    }

    /// Custom glass effect with full control
    func customGlass(
        blurMaterial: Material = .ultraThinMaterial,
        tint: Color = Color.white.opacity(0.1),
        border: LinearGradient,
        borderWidth: CGFloat = 1.0,
        glowColor: Color? = nil,
        glowRadius: CGFloat = 15,
        cornerRadius: CGFloat = 14
    ) -> some View {
        self.modifier(GlassEffect(
            blurMaterial: blurMaterial,
            tintColor: tint,
            borderGradient: border,
            borderWidth: borderWidth,
            glowColor: glowColor,
            glowRadius: glowRadius,
            cornerRadius: cornerRadius
        ))
    }
}

// MARK: - Shimmer Border Gradient

func shimmerBorder() -> LinearGradient {
    LinearGradient(
        colors: [
            Color.white.opacity(0.6),
            Color.white.opacity(0.3),
            Color.white.opacity(0.1),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Contextual Glow Colors

struct GlowColors {
    static let success = Color(red: 0.3, green: 0.95, blue: 0.5).opacity(0.6)
    static let error = Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.6)
    static let info = Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.4)
    static let warning = Color(red: 1.0, green: 0.8, blue: 0.3).opacity(0.5)
    static let purple = Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.5)
    static let cyan = Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.6)
    static let pink = Color(red: 1.0, green: 0.4, blue: 0.6).opacity(0.7)
    static let teal = Color(red: 0.2, green: 0.9, blue: 0.9).opacity(0.5)
}

// MARK: - Helper Extension

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
