//
//  TimeControlView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

struct TimeControlView: View {
    @Environment(ControllerViewModel.self) private var controllerVM
    @State private var customTime: Date = Date()
    @State private var freezeTime: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.black.opacity(0.04))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                    )

                Text("Time Control")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }

            VStack(spacing: 18) {
                // Time picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Display Time")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    DatePicker(
                        "Select Time",
                        selection: $customTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .tint(.blue)
                }

                // Preview card
                VStack(alignment: .leading, spacing: 10) {
                    Text("Preview")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Lock Screen")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)

                            Text(TimeController.shared.formatTime(customTime))
                                .font(.system(size: 32, weight: .thin))
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Status Bar")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)

                            Text(TimeController.shared.formatTimeForStatusBar(customTime))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Freeze toggle
                freezeToggle

                // Action buttons
                HStack(spacing: 12) {
                    updateButton
                    syncButton
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private var freezeToggle: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.cyan.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "snowflake")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.cyan)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Freeze Time")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Don't advance automatically")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $freezeTime)
                .labelsHidden()
                .tint(.cyan)
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var updateButton: some View {
        Button { updateTime() } label: {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("Update")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.blue)
            .cornerRadius(10)
        }
    }

    private var syncButton: some View {
        Button { syncCurrentTime() } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                Text("Sync Now")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.green)
            .cornerRadius(10)
        }
    }

    private func updateTime() {
        controllerVM.updateTime(customTime, freeze: freezeTime)
    }

    private func syncCurrentTime() {
        customTime = Date()
        freezeTime = false
        controllerVM.updateTime(customTime, freeze: false)
    }
}

#Preview {
    ZStack {
        AppGradients.cosmicBackground.ignoresSafeArea()
        TimeControlView()
            .padding()
            .environment(ControllerViewModel(multipeerService: MultipeerService(mode: .controller)))
    }
}
