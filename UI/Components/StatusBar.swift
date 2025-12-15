//
//  StatusBar.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

/// Custom status bar for Mimic displays (to show controlled time and fake signal)
struct StatusBar: View {
    let time: Date
    let signalStrength: Int? // 0-4 bars
    let carrierName: String?
    let batteryPercent: Int? // 0-100

    var body: some View {
        HStack(spacing: 4) {
            // Leading: Time
            Text(TimeController.shared.formatTimeForStatusBar(time))
                .font(.statusBar)
                .foregroundColor(.white)

            Spacer()

            // Trailing: Signal, WiFi, Battery
            HStack(spacing: 4) {
                // Signal strength
                if let bars = signalStrength {
                    SignalBarsView(bars: bars)
                }

                // WiFi
                Image(systemName: "wifi")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                // Battery
                BatteryView(percent: batteryPercent ?? 100)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .frame(height: 44)
    }
}

struct SignalBarsView: View {
    let bars: Int // 0-4

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < bars ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 3, height: CGFloat(4 + index * 2))
            }
        }
        .frame(width: 17, height: 12)
    }
}

struct BatteryView: View {
    let percent: Int // 0-100

    var body: some View {
        HStack(spacing: 2) {
            // Battery body
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2.5)
                    .stroke(Color.white, lineWidth: 1)
                    .frame(width: 22, height: 11)

                // Fill level
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(batteryColor)
                    .frame(width: CGFloat(percent) / 100 * 18, height: 7)
                    .padding(.leading, 2)
            }

            // Battery tip
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.white)
                .frame(width: 2, height: 4)
        }
    }

    var batteryColor: Color {
        if percent <= 20 {
            return Color.red
        } else {
            return Color.white
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        StatusBar(
            time: Date(),
            signalStrength: 4,
            carrierName: "Verizon",
            batteryPercent: 85
        )
    }
}
