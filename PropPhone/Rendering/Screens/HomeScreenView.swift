//
//  HomeScreenView.swift
//  PropPhone
//
//  A believable springboard: wallpaper, icon grid, search pill, dock.
//  The Phone icon opens the working Phone app; other icons give a
//  subtle press bounce so an actor tapping around never breaks the
//  illusion with a dead screen.
//

import SwiftUI

struct HomeScreenView: View {
    let runtime: PhoneRuntime
    let displayTime: Date

    private let grid = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            WallpaperView(
                spec: runtime.state.profile.wallpaper,
                assetGeneration: runtime.assetGeneration
            )
            .overlay(Color.black.opacity(0.08))
            .ignoresSafeArea()

            VStack(spacing: 0) {
                IOSStatusBar(
                    style: .inApp,
                    spec: runtime.state.profile.statusBar,
                    time: displayTime,
                    tint: .white
                )
                .padding(.horizontal, 20)
                .padding(.top, DeviceMetrics.top - 47)

                LazyVGrid(columns: grid, spacing: 24) {
                    ForEach(HomeIcon.page, id: \.name) { icon in
                        HomeIconView(icon: icon, displayTime: displayTime) {
                            handleTap(icon)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)

                Spacer()

                Capsule()
                    .fill(.ultraThinMaterial)
                    .frame(width: 76, height: 26)
                    .overlay {
                        HStack(spacing: 4) {
                            Image(systemName: "magnifyingglass").font(.system(size: 11, weight: .semibold))
                            Text("Search").font(.system(size: 13))
                        }
                        .foregroundStyle(.white)
                    }
                    .padding(.bottom, 12)

                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(height: 94)
                    .overlay {
                        HStack(spacing: 26) {
                            ForEach(HomeIcon.dock, id: \.name) { icon in
                                HomeIconView(icon: icon, displayTime: displayTime, showLabel: false) {
                                    handleTap(icon)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 14)

                HomeIndicator()
            }
        }
        .environment(\.colorScheme, .dark)
    }

    private func handleTap(_ icon: HomeIcon) {
        switch icon.action {
        case .none: break
        case .phone: runtime.openPhoneApp()
        case .messages: runtime.openMessagesApp()
        case .photos: runtime.openPhotosApp()
        }
    }
}

// MARK: - Icon model

enum HomeIconAction {
    case none, phone, messages, photos
}

struct HomeIcon {
    var name: String
    var symbol: String
    var symbolColor: Color = .white
    var colors: [Color]
    var action: HomeIconAction = .none
    /// Renders the current day number instead of a symbol (Calendar).
    var showsDay = false

    static let page: [HomeIcon] = [
        HomeIcon(name: "FaceTime", symbol: "video.fill", colors: [Color(red: 0.44, green: 0.89, blue: 0.44), Color(red: 0.06, green: 0.77, blue: 0.24)]),
        HomeIcon(name: "Calendar", symbol: "", symbolColor: .black, colors: [.white, Color(white: 0.93)], showsDay: true),
        HomeIcon(name: "Photos", symbol: "camera.macro", symbolColor: .pink, colors: [.white, Color(white: 0.95)], action: .photos),
        HomeIcon(name: "Camera", symbol: "camera.fill", symbolColor: .black, colors: [Color(white: 0.85), Color(white: 0.72)]),
        HomeIcon(name: "Mail", symbol: "envelope.fill", colors: [Color(red: 0.35, green: 0.68, blue: 0.99), Color(red: 0.06, green: 0.43, blue: 0.93)]),
        HomeIcon(name: "Clock", symbol: "clock.fill", colors: [Color(white: 0.15), Color.black]),
        HomeIcon(name: "Maps", symbol: "location.north.fill", symbolColor: .white, colors: [Color(red: 0.36, green: 0.78, blue: 0.42), Color(red: 0.2, green: 0.62, blue: 0.86)]),
        HomeIcon(name: "Weather", symbol: "cloud.sun.fill", colors: [Color(red: 0.35, green: 0.7, blue: 0.98), Color(red: 0.15, green: 0.45, blue: 0.9)]),
        HomeIcon(name: "Notes", symbol: "note.text", symbolColor: Color(red: 0.95, green: 0.77, blue: 0.06), colors: [.white, Color(white: 0.95)]),
        HomeIcon(name: "Settings", symbol: "gearshape.fill", symbolColor: Color(white: 0.35), colors: [Color(white: 0.88), Color(white: 0.75)]),
        HomeIcon(name: "Music", symbol: "music.note", symbolColor: .white, colors: [Color(red: 0.99, green: 0.36, blue: 0.43), Color(red: 0.93, green: 0.2, blue: 0.29)]),
        HomeIcon(name: "Wallet", symbol: "wallet.pass.fill", colors: [Color(white: 0.15), Color.black]),
        HomeIcon(name: "App Store", symbol: "square.stack.3d.up.fill", colors: [Color(red: 0.35, green: 0.68, blue: 0.99), Color(red: 0.06, green: 0.43, blue: 0.93)]),
        HomeIcon(name: "Health", symbol: "heart.fill", symbolColor: .pink, colors: [.white, Color(white: 0.95)]),
        HomeIcon(name: "Podcasts", symbol: "antenna.radiowaves.left.and.right", colors: [Color(red: 0.7, green: 0.35, blue: 0.95), Color(red: 0.52, green: 0.19, blue: 0.86)]),
        HomeIcon(name: "TV", symbol: "play.tv.fill", colors: [Color(white: 0.15), Color.black])
    ]

    static let dock: [HomeIcon] = [
        HomeIcon(name: "Phone", symbol: "phone.fill", colors: [Color(red: 0.44, green: 0.89, blue: 0.44), Color(red: 0.06, green: 0.77, blue: 0.24)], action: .phone),
        HomeIcon(name: "Safari", symbol: "safari.fill", symbolColor: Color(red: 0.16, green: 0.5, blue: 0.96), colors: [.white, Color(white: 0.93)]),
        HomeIcon(name: "Messages", symbol: "bubble.left.fill", colors: [Color(red: 0.44, green: 0.89, blue: 0.44), Color(red: 0.06, green: 0.77, blue: 0.24)], action: .messages),
        HomeIcon(name: "Music", symbol: "music.note", colors: [Color(red: 0.99, green: 0.36, blue: 0.43), Color(red: 0.93, green: 0.2, blue: 0.29)])
    ]
}

struct HomeIconView: View {
    let icon: HomeIcon
    let displayTime: Date
    var showLabel = true
    var action: () -> Void

    @State private var pressed = false

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 13.5, style: .continuous)
                    .fill(LinearGradient(colors: icon.colors, startPoint: .top, endPoint: .bottom))

                if icon.showsDay {
                    VStack(spacing: 0) {
                        Text(displayTime, format: .dateTime.weekday(.wide))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.red)
                            .textCase(.uppercase)
                        Text(displayTime, format: .dateTime.day())
                            .font(.system(size: 30, weight: .light))
                            .foregroundStyle(.black)
                    }
                } else {
                    Image(systemName: icon.symbol)
                        .font(.system(size: 27))
                        .foregroundStyle(icon.symbolColor)
                }
            }
            .frame(width: 60, height: 60)
            .scaleEffect(pressed ? 0.85 : 1)

            if showLabel {
                Text(icon.name)
                    .font(.system(size: 11))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                    .lineLimit(1)
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { pressed = false }
                action()
            }
        }
    }
}
