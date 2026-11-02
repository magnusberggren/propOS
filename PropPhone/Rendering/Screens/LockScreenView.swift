//
//  LockScreenView.swift
//  PropPhone
//
//  iOS 17-style lock screen: padlock under the island, date line,
//  large rounded clock, bottom-anchored notification stack,
//  flashlight/camera buttons. Swipe up unlocks.
//

import SwiftUI

struct LockScreenView: View {
    let runtime: PhoneRuntime
    let displayTime: Date

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                WallpaperView(
                    spec: runtime.state.profile.wallpaper,
                    assetGeneration: runtime.assetGeneration
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    IOSStatusBar(
                        style: .lockScreen,
                        spec: runtime.state.profile.statusBar,
                        time: displayTime,
                        tint: .white
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, DeviceMetrics.top - 47)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.top, 24)

                    Text(displayTime, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.top, 14)

                    Text(displayTime, format: .dateTime.hour().minute())
                        .font(.system(size: 98, weight: .bold, design: .rounded))
                        .kerning(-2)
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.top, -12)

                    Spacer()

                    if !runtime.state.lockNotifications.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(runtime.state.lockNotifications) { item in
                                NotificationBanner(item: item)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 20)
                    }

                    HStack {
                        QuickActionButton(systemName: "flashlight.off.fill")
                        Spacer()
                        QuickActionButton(systemName: "camera.fill")
                    }
                    .padding(.horizontal, 46)
                    .padding(.bottom, 26)

                    HomeIndicator()
                }
            }
            .environment(\.colorScheme, .dark)
            .offset(y: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        dragOffset = min(0, value.translation.height * 0.6)
                    }
                    .onEnded { value in
                        if value.translation.height < -90 {
                            withAnimation(.easeOut(duration: 0.25)) {
                                dragOffset = -geo.size.height
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                runtime.unlock()
                                dragOffset = 0
                            }
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
    }
}

// MARK: - Notification banner

struct NotificationBanner: View {
    let item: NotificationItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            FakeAppIcon(app: item.app, size: 38)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                Text(item.body)
                    .font(.system(size: 15))
                    .lineLimit(4)
            }
            .foregroundStyle(.primary)

            Spacer(minLength: 4)

            Text(item.timeLabel)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.top, 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Quick action

struct QuickActionButton: View {
    let systemName: String

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 52, height: 52)
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Fake app icons (for notification banners)

struct FakeAppIcon: View {
    let app: FakeApp
    var size: CGFloat = 38

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                .fill(background)
            symbol
                .font(.system(size: size * 0.5, weight: .regular))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }

    private var background: LinearGradient {
        switch app {
        case .messages:
            return LinearGradient(colors: [Color(red: 0.44, green: 0.89, blue: 0.44), Color(red: 0.06, green: 0.77, blue: 0.24)], startPoint: .top, endPoint: .bottom)
        case .mail:
            return LinearGradient(colors: [Color(red: 0.16, green: 0.58, blue: 0.98), Color(red: 0.05, green: 0.42, blue: 0.92)], startPoint: .top, endPoint: .bottom)
        case .phone:
            return LinearGradient(colors: [Color(red: 0.44, green: 0.89, blue: 0.44), Color(red: 0.06, green: 0.77, blue: 0.24)], startPoint: .top, endPoint: .bottom)
        case .calendar:
            return LinearGradient(colors: [.white, Color(white: 0.94)], startPoint: .top, endPoint: .bottom)
        case .photos:
            return LinearGradient(colors: [.white, Color(white: 0.95)], startPoint: .top, endPoint: .bottom)
        case .bank:
            return LinearGradient(colors: [Color(red: 0.1, green: 0.13, blue: 0.3), Color(red: 0.05, green: 0.07, blue: 0.2)], startPoint: .top, endPoint: .bottom)
        }
    }

    @ViewBuilder
    private var symbol: some View {
        switch app {
        case .messages: Image(systemName: "bubble.left.fill")
        case .mail: Image(systemName: "envelope.fill")
        case .phone: Image(systemName: "phone.fill")
        case .calendar:
            Text("6").foregroundStyle(.black).font(.system(size: size * 0.5, weight: .light))
        case .photos:
            Image(systemName: "camera.macro").foregroundStyle(.pink)
        case .bank: Image(systemName: "creditcard.fill")
        }
    }
}
