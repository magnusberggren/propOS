//
//  BlurEffectView.swift
//  PropPhone
//
//  Enhanced blur effect with glassmorphism support
//

import SwiftUI
import UIKit

// MARK: - Enhanced Blur Effect View

/// UIViewRepresentable wrapper for UIBlurEffect with enhanced glassmorphism support
struct BlurEffectView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    var intensity: CGFloat = 1.0

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        view.alpha = intensity
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
        uiView.alpha = intensity
    }
}

// MARK: - Enhanced Blur with Glassmorphism

struct EnhancedBlurView: View {
    let style: UIBlurEffect.Style
    let tint: Color
    let border: LinearGradient?
    let borderWidth: CGFloat
    let glowColor: Color?
    let glowRadius: CGFloat
    let cornerRadius: CGFloat

    init(
        style: UIBlurEffect.Style = .systemUltraThinMaterial,
        tint: Color = Color.white.opacity(0.1),
        border: LinearGradient? = nil,
        borderWidth: CGFloat = 1.0,
        glowColor: Color? = nil,
        glowRadius: CGFloat = 15,
        cornerRadius: CGFloat = 14
    ) {
        self.style = style
        self.tint = tint
        self.border = border
        self.borderWidth = borderWidth
        self.glowColor = glowColor
        self.glowRadius = glowRadius
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        ZStack {
            // Blur layer
            BlurEffectView(style: style)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            // Tint overlay
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(tint)
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    border ?? LinearGradient(
                        colors: [Color.white.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: borderWidth
                )
        )
        .if(glowColor != nil) { view in
            view.shadow(color: glowColor!, radius: glowRadius, x: 0, y: 0)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Basic blur background
    func blurBackground(
        style: UIBlurEffect.Style = .systemMaterial,
        intensity: CGFloat = 1.0
    ) -> some View {
        self.background(BlurEffectView(style: style, intensity: intensity))
    }

    /// Enhanced blur background with glassmorphism
    func enhancedBlurBackground(
        style: UIBlurEffect.Style = .systemUltraThinMaterial,
        tint: Color = Color.white.opacity(0.1),
        border: LinearGradient? = nil,
        borderWidth: CGFloat = 1.0,
        glowColor: Color? = nil,
        glowRadius: CGFloat = 15,
        cornerRadius: CGFloat = 14
    ) -> some View {
        self.background(
            EnhancedBlurView(
                style: style,
                tint: tint,
                border: border,
                borderWidth: borderWidth,
                glowColor: glowColor,
                glowRadius: glowRadius,
                cornerRadius: cornerRadius
            )
        )
    }
}

