//
//  LockScreenView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

struct LockScreenView: View {
    let time: Date
    let notifications: [PropNotification]
    let signalStrength: Int?
    let carrierName: String?
    let batteryPercent: Int?
    var wallpaper: Wallpaper = .black
    var customWallpaperImage: UIImage? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background - wallpaper or custom image
                backgroundView
                    .frame(width: geometry.size.width, height: geometry.size.height)

                // Content overlay
                VStack(spacing: 0) {
                    // Custom status bar at top - positioned below Dynamic Island
                    StatusBar(
                        time: time,
                        signalStrength: signalStrength ?? 4,
                        carrierName: carrierName,
                        batteryPercent: batteryPercent ?? 100
                    )
                    .padding(.top, geometry.safeAreaInsets.top)

                    // Large time display
                    VStack(spacing: 8) {
                        // Time
                        Text(TimeController.shared.formatTime(time))
                            .font(.system(size: 84, weight: .thin, design: .default))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)

                        // Date
                        Text(TimeController.shared.formatFullDate(time))
                            .font(.system(size: 20, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                    .padding(.top, 30)

                    Spacer()

                    // Notifications in middle (if any)
                    if !notifications.isEmpty {
                        VStack(spacing: 10) {
                            ForEach(notifications) { notification in
                                NotificationBannerView(notification: notification)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    Spacer()

                    // Bottom action hint
                    VStack(spacing: 8) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .opacity(0.5)

                        Text("Swipe up to open")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white)
                            .opacity(0.5)
                    }
                    .padding(.bottom, 8)

                    // Bottom quick action buttons
                    HStack {
                        // Flashlight button
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 50, height: 50)

                            Image(systemName: "flashlight.off.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        // Camera button
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 50, height: 50)

                            Image(systemName: "camera.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 50)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 12)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
    }

    @ViewBuilder
    private var backgroundView: some View {
        if let customImage = customWallpaperImage {
            Image(uiImage: customImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        } else {
            wallpaper.background
        }
    }
}

#Preview {
    LockScreenView(
        time: Date(),
        notifications: [
            PropNotification(
                appName: "Messages",
                appIcon: "message.fill",
                title: "John Doe",
                body: "Hey, are you free for dinner tonight?",
                isUrgent: false
            ),
            PropNotification(
                appName: "Mail",
                appIcon: "envelope.fill",
                title: "Work Email",
                body: "Important update regarding the project",
                isUrgent: true
            )
        ],
        signalStrength: 4,
        carrierName: "Verizon",
        batteryPercent: 85
    )
}
