//
//  DeviceListView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

struct DeviceListView: View {
    @Environment(ControllerViewModel.self) private var controllerVM

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.7))

                Text("Devices")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 4)

            // Connected devices
            if !controllerVM.connectedDevices.isEmpty {
                VStack(spacing: 10) {
                    ForEach(controllerVM.connectedDevices) { device in
                        DeviceRow(device: device, isConnected: true)
                    }
                }
            }

            // Discovered devices
            if !controllerVM.discoveredDevices.isEmpty {
                Text("Available")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.horizontal, 4)
                    .padding(.top, 8)

                VStack(spacing: 10) {
                    ForEach(controllerVM.discoveredDevices) { device in
                        DeviceRow(device: device, isConnected: false)
                    }
                }
            }

            // Empty state with guide
            if controllerVM.connectedDevices.isEmpty && controllerVM.discoveredDevices.isEmpty {
                VStack(spacing: 20) {
                    // Searching indicator
                    VStack(spacing: 14) {
                        Circle()
                            .fill(Color.black.opacity(0.04))
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 30, weight: .medium))
                                    .foregroundColor(.primary.opacity(0.5))
                            )

                        Text("Searching for Mimic devices...")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary.opacity(0.8))
                    }

                    // Connection guide
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to connect")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary.opacity(0.7))

                        ConnectionStep(number: 1, text: "Open PropPhone on the prop device")
                        ConnectionStep(number: 2, text: "Select \"Mimic\" mode")
                        ConnectionStep(number: 3, text: "The device will appear here automatically")
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

struct DeviceRow: View {
    @Environment(ControllerViewModel.self) private var controllerVM
    let device: PeerDevice
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Device icon
            Circle()
                .fill(Color.black.opacity(0.04))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: isConnected ? "iphone.gen3.circle.fill" : "iphone.gen3.circle")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isConnected ? .green : .primary.opacity(0.6))
                )

            // Device info
            VStack(alignment: .leading, spacing: 3) {
                Text(device.id)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text(device.mode.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Action button
            actionButton
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var actionButton: some View {
        if isConnected {
            Button {
                controllerVM.disconnectFrom(device: device)
            } label: {
                Text("Disconnect")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(8)
            }
        } else {
            Button {
                controllerVM.connectTo(device: device)
            } label: {
                Text("Connect")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
    }
}

struct ConnectionStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Text("\(number)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.blue)
                .frame(width: 22, height: 22)
                .background(Color.blue.opacity(0.15))
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ZStack {
        AppGradients.cosmicBackground.ignoresSafeArea()
        DeviceListView()
            .padding()
            .environment(ControllerViewModel(multipeerService: MultipeerService(mode: .controller)))
    }
}
