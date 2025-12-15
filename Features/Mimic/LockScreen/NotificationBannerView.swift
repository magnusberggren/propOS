//
//  NotificationBannerView.swift
//  PropPhone
//
//  Recreating iOS lock screen notification style
//

import SwiftUI

struct NotificationBannerView: View {
    let notification: PropNotification

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // App icon - iOS style: ~38pt with continuous corner radius
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconBackgroundColor)
                    .frame(width: 38, height: 38)

                Image(systemName: notification.appIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: 1) {
                // Title - 15pt semibold (iOS uses this for notification titles)
                Text(notification.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // Body - 15pt regular
                Text(notification.body)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.primary.opacity(0.8))
                    .lineLimit(4)
            }

            Spacer(minLength: 8)

            // Time ago - 13pt, secondary color, aligned to top
            Text(notification.timeAgo)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.red)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.yellow, lineWidth: 5)
        )
    }

    private var iconBackgroundColor: Color {
        switch notification.appName.lowercased() {
        case "messages":
            return Color(red: 0.30, green: 0.85, blue: 0.40) // iOS Messages green
        case "mail":
            return Color(red: 0.0, green: 0.48, blue: 1.0) // iOS Mail blue
        case "phone", "facetime":
            return Color(red: 0.30, green: 0.85, blue: 0.40)
        case "calendar":
            return Color.red
        case "reminders":
            return Color.orange
        case "notes":
            return Color.yellow
        case "whatsapp":
            return Color(red: 0.15, green: 0.68, blue: 0.38)
        case "instagram":
            return Color(red: 0.88, green: 0.19, blue: 0.42)
        case "twitter", "x":
            return Color.black
        case "slack":
            return Color(red: 0.38, green: 0.13, blue: 0.51)
        case "messenger":
            return Color(red: 0.0, green: 0.47, blue: 1.0)
        default:
            return Color.gray
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 8) {
            NotificationBannerView(
                notification: PropNotification(
                    appName: "Messages",
                    appIcon: "message.fill",
                    title: "John Doe",
                    body: "Hey, are you free for dinner tonight?",
                    isUrgent: false
                )
            )

            NotificationBannerView(
                notification: PropNotification(
                    appName: "Mail",
                    appIcon: "envelope.fill",
                    title: "Work Email",
                    body: "Important update regarding the project",
                    isUrgent: true
                )
            )
        }
        .padding(.horizontal, 16)
    }
}
