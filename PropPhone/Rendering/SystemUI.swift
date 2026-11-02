//
//  SystemUI.swift
//  PropPhone
//
//  Shared iOS system chrome: status bar, home indicator, avatars,
//  wallpaper resolution, device metrics. All sizes are fixed points
//  measured against reference screenshots — never Dynamic Type —
//  so rendering is deterministic on camera.
//

import SwiftUI

// MARK: - Device metrics

enum DeviceMetrics {
    /// Safe-area insets of the physical device, captured once. Falls back to
    /// Dynamic Island phone metrics.
    static var insets: UIEdgeInsets = {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first
        let window = scene?.windows.first
        var insets = window?.safeAreaInsets ?? UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        if insets.top == 0 { insets.top = 59 }
        if insets.bottom == 0 { insets.bottom = 34 }
        return insets
    }()

    static var top: CGFloat { insets.top }
    static var bottom: CGFloat { insets.bottom }
}

// MARK: - Status bar

enum StatusBarStyle {
    /// In-app: time on the left, indicators on the right.
    case inApp
    /// Lock screen: carrier on the left, no time (the big clock shows it).
    case lockScreen
    /// Dark content for light app backgrounds.
    var defaultsToDarkContent: Bool { self == .inApp }
}

struct IOSStatusBar: View {
    var style: StatusBarStyle
    var spec: StatusBarSpec
    var time: Date
    var tint: Color

    var body: some View {
        HStack {
            Group {
                switch style {
                case .inApp:
                    Text(time, format: .dateTime.hour().minute())
                        .font(.system(size: 16, weight: .semibold))
                        .monospacedDigit()
                        .kerning(-0.3)
                case .lockScreen:
                    Text(spec.carrierName)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .frame(width: 130, alignment: .center)

            Spacer()

            HStack(spacing: 7) {
                SignalBars(bars: spec.signalBars, tint: tint)
                if spec.showWiFi {
                    Image(systemName: "wifi")
                        .font(.system(size: 15, weight: .semibold))
                }
                BatteryIndicator(percent: spec.batteryPercent, showPercent: spec.showBatteryPercent, tint: tint)
            }
            .frame(width: 130, alignment: .center)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 6)
        .frame(height: 22)
    }
}

struct SignalBars: View {
    var bars: Int
    var tint: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 1.7) {
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(tint.opacity(i < bars ? 1 : 0.3))
                    .frame(width: 3.4, height: 4.5 + CGFloat(i) * 2.2)
            }
        }
    }
}

struct BatteryIndicator: View {
    var percent: Int
    var showPercent: Bool
    var tint: Color

    var body: some View {
        HStack(spacing: 1.5) {
            ZStack {
                RoundedRectangle(cornerRadius: 4.2, style: .continuous)
                    .strokeBorder(tint.opacity(0.4), lineWidth: 1)
                    .frame(width: 25, height: 13)

                GeometryReader { _ in
                    RoundedRectangle(cornerRadius: 2.4, style: .continuous)
                        .fill(fillColor)
                        .frame(width: max(3, 21 * CGFloat(percent) / 100), height: 9)
                        .offset(x: 2, y: 2)
                }
                .frame(width: 25, height: 13)

                if showPercent {
                    Text("\(percent)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(percent > 25 ? Color.black : tint)
                }
            }
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(tint.opacity(0.4))
                .frame(width: 1.7, height: 4.5)
        }
    }

    private var fillColor: Color {
        if percent <= 20 { return .red }
        return showPercent ? .green : tint
    }
}

// MARK: - Home indicator

struct HomeIndicator: View {
    var tint: Color = .white

    var body: some View {
        Capsule()
            .fill(tint)
            .frame(width: 139, height: 5)
            .padding(.bottom, 9)
    }
}

// MARK: - Wallpaper

struct WallpaperView: View {
    var spec: WallpaperSpec
    /// Ties re-renders to asset arrival.
    var assetGeneration: Int = 0

    var body: some View {
        GeometryReader { geo in
            Group {
                switch spec {
                case .builtin(let name):
                    if UIImage(named: name) != nil {
                        Image(name)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        LinearGradient(
                            colors: [Color(red: 0.08, green: 0.1, blue: 0.25), Color(red: 0.03, green: 0.03, blue: 0.09)],
                            startPoint: .top, endPoint: .bottom
                        )
                    }
                case .asset(let ref):
                    if let image = AssetStore.shared.image(for: ref) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.black
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .id(assetGeneration)
        }
    }
}

// MARK: - Avatar

struct AvatarView: View {
    var name: String
    var monogram: String
    var imageAsset: AssetRef?
    var size: CGFloat
    var assetGeneration: Int = 0

    var body: some View {
        Group {
            if let image = AssetStore.shared.image(for: imageAsset) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color(white: 0.62), Color(white: 0.47)],
                        startPoint: .top, endPoint: .bottom
                    )
                    Text(monogram)
                        .font(.system(size: size * 0.42, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .id(assetGeneration)
    }
}

// MARK: - Formatting helpers

enum PropFormat {
    static func duration(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    static func callTimer(since start: Date, now: Date) -> String {
        let s = max(0, Int(now.timeIntervalSince(start)))
        if s >= 3600 {
            return String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
        }
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}
