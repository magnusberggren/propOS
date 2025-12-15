//
//  CallActionButtons.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

struct CallActionButtons: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Top row: Remind Me and Message
            HStack(spacing: Spacing.callScreenButtonSpacing) {
                SmallCallButton(
                    icon: "clock.fill",
                    label: "Remind Me",
                    color: .white.opacity(0.2)
                )

                SmallCallButton(
                    icon: "message.fill",
                    label: "Message",
                    color: .white.opacity(0.2)
                )
            }

            // Bottom row: Decline and Accept
            HStack(spacing: Spacing.callScreenButtonSpacing) {
                CallButton(
                    icon: "phone.down.fill",
                    color: .callRed
                )

                CallButton(
                    icon: "phone.fill",
                    color: .callGreen
                )
            }
        }
    }
}

struct CallButton: View {
    let icon: String
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: Spacing.callButtonSize, height: Spacing.callButtonSize)

            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
        }
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct SmallCallButton: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: Spacing.smallButtonSize, height: Spacing.smallButtonSize)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }

            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CallActionButtons()
    }
}
