//
//  ModeSelectionView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

struct ModeSelectionView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(AuthenticationService.self) private var authService
    @State private var showProfile = false

    var body: some View {
        @Bindable var viewModel = appViewModel

        NavigationStack {
            ZStack {
                // Light gray background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 48) {
                    // Clean header
                    VStack(spacing: 14) {
                        // Simple icon
                        Circle()
                            .fill(Color.black.opacity(0.04))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "iphone.gen3")
                                    .font(.system(size: 36, weight: .light))
                                    .foregroundColor(.primary.opacity(0.7))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                            )

                        Text("Prop Phone")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("Film & TV Production Tool")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)

                    // Mode selection cards
                    VStack(spacing: 12) {
                        ModeCard(
                            icon: "slider.horizontal.3",
                            title: "Controller",
                            description: "Control other devices and trigger events"
                        ) {
                            appViewModel.switchMode(to: .controller)
                        }

                        ModeCard(
                            icon: "rectangle.on.rectangle",
                            title: "Mimic",
                            description: "Display fake iPhone screens for filming"
                        ) {
                            appViewModel.switchMode(to: .mimic)
                        }

                        ModeCard(
                            icon: "play.rectangle.fill",
                            title: "Demo",
                            description: "Preview all screens with sample data"
                        ) {
                            appViewModel.switchMode(to: .demo)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // Minimal info text
                    Text("Controller sends commands  ·  Mimic displays on camera")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 30)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(.primary.opacity(0.7))
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .environment(authService)
            }
        }
    }
}

struct ModeCard: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Clean icon circle
                Circle()
                    .fill(Color.black.opacity(0.04))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(.primary.opacity(0.7))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                    )

                // Text content
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black.opacity(0.2))
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    ModeSelectionView()
        .environment(AppViewModel())
}
