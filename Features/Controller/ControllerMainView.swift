//
//  ControllerMainView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

struct ControllerMainView: View {
    @Environment(ControllerViewModel.self) private var controllerVM
    @Environment(AppViewModel.self) private var appViewModel

    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Connection status
                    ConnectionStatusCard()
                        .padding(.horizontal)
                        .padding(.top)

                    // Device list (compact)
                    if !controllerVM.connectedDevices.isEmpty || !controllerVM.discoveredDevices.isEmpty {
                        DeviceListView()
                            .padding(.top)
                    }

                    // Tab picker for Phone vs Legacy controls
                    Picker("Control Mode", selection: $selectedTab) {
                        Text("Phone").tag(0)
                        Text("Legacy").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top)

                    if selectedTab == 0 {
                        phoneControlsView
                    } else {
                        if !controllerVM.connectedDevices.isEmpty {
                            legacyControlsView
                        } else {
                            noDevicesConnectedView
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("Controller")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        appViewModel.returnToModeSelection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Phone Controls (New Flow)

    private var phoneControlsView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Phone selector
                PhoneSelectorView(viewModel: controllerVM)

                // State toggle (Idle/Lock)
                if controllerVM.selectedPhone != nil {
                    StateToggleView(viewModel: controllerVM)
                }

                // Time control
                TimeControlCard(viewModel: controllerVM)

                // Contact grid
                ContactGridView(viewModel: controllerVM)
                    .frame(height: 200)

                // Contact actions
                ContactActionView(viewModel: controllerVM)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Legacy Controls

    private var legacyControlsView: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                CallControlView()
                NotificationControlView()
                TimeControlView()
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private var noDevicesConnectedView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No Devices Connected")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)

            Text("Connect to a device above to start controlling")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        .padding()
    }
}

// MARK: - State Toggle View

struct StateToggleView: View {
    @Bindable var viewModel: ControllerViewModel

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Idle button
            StateButton(
                title: "Idle",
                icon: "iphone.gen3",
                isSelected: viewModel.currentScreenState == .idle
            ) {
                viewModel.switchToIdle()
            }

            // Lock Screen button
            StateButton(
                title: "Lock Screen",
                icon: "lock.iphone",
                isSelected: viewModel.currentScreenState == .lockScreen
            ) {
                viewModel.switchToLockScreen()
            }
        }
        .padding(.horizontal, Spacing.md)
    }
}

struct StateButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .primary)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.black.opacity(0.06), lineWidth: isSelected ? 2 : 0.5)
            )
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Time Control Card

struct TimeControlCard: View {
    @Bindable var viewModel: ControllerViewModel
    @State private var showingDatePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Time & Date")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.horizontal, Spacing.md)

            HStack(spacing: Spacing.md) {
                // Time/Date display button
                Button {
                    showingDatePicker = true
                } label: {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.customTime, style: .time)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text(viewModel.customTime, style: .date)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(Spacing.md)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
                }

                // Freeze toggle
                Button {
                    viewModel.freezeTime.toggle()
                    viewModel.updateTime(viewModel.customTime, freeze: viewModel.freezeTime)
                } label: {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: viewModel.freezeTime ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(viewModel.freezeTime ? .orange : .green)

                        Text(viewModel.freezeTime ? "Frozen" : "Live")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(viewModel.freezeTime ? .orange : .green)
                    }
                    .frame(width: 60)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
                }

                // Send time button
                Button {
                    viewModel.updateTime(viewModel.customTime, freeze: viewModel.freezeTime)
                } label: {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)

                        Text("Send")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.blue)
                    }
                    .frame(width: 60)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(selectedDate: $viewModel.customTime)
        }
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker("Select Date & Time", selection: $selectedDate)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Set Time")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Connection Status Card

struct ConnectionStatusCard: View {
    @Environment(ControllerViewModel.self) private var controllerVM

    private var isActive: Bool {
        controllerVM.multipeerService.isActive
    }

    var body: some View {
        HStack(spacing: 14) {
            // Status icon
            Circle()
                .fill(Color.black.opacity(0.04))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: isActive ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isActive ? .green : .red)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(isActive ? "Browsing for Devices" : "Not Active")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Text("\(controllerVM.connectedDevices.count) connected")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status indicator dot
            Circle()
                .fill(isActive ? Color.green : Color.red)
                .frame(width: 10, height: 10)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    ControllerMainView()
        .environment(ControllerViewModel(multipeerService: MultipeerService(mode: .controller)))
        .environment(AppViewModel())
}
