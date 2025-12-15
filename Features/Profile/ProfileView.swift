//
//  ProfileView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI
import AuthenticationServices

struct ProfileView: View {
    @Environment(AuthenticationService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var showSignOutConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var isGuest: Bool {
        authService.currentUser?.appleUserID == nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        VStack(spacing: 16) {
                            // Avatar
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: isGuest ? "person.fill" : "person.crop.circle.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.blue)
                                )

                            // Name and email
                            VStack(spacing: 4) {
                                Text(authService.currentUser?.username ?? "User")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.primary)

                                if let email = authService.currentUser?.email {
                                    Text(email)
                                        .font(.system(size: 15))
                                        .foregroundStyle(.secondary)
                                }
                            }

                            // Account badge
                            HStack(spacing: 6) {
                                Image(systemName: isGuest ? "person.fill.questionmark" : "apple.logo")
                                    .font(.system(size: 12))
                                Text(isGuest ? "Guest Account" : "Apple ID")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(isGuest ? .orange : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(isGuest ? Color.orange.opacity(0.1) : Color.secondary.opacity(0.1))
                            )
                        }
                        .padding(.top, 20)

                        // Account section
                        VStack(spacing: 0) {
                            if isGuest {
                                // Upgrade to Apple ID option
                                Button {
                                    Task {
                                        do {
                                            try await authService.signInWithApple()
                                            dismiss()
                                        } catch let error as AuthenticationError {
                                            if error != .canceled {
                                                errorMessage = error.localizedDescription
                                                showError = true
                                            }
                                        } catch {
                                            errorMessage = error.localizedDescription
                                            showError = true
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "apple.logo")
                                            .font(.system(size: 18))
                                            .frame(width: 28)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Sign in with Apple")
                                                .font(.system(size: 16, weight: .medium))
                                            Text("Sync your phones across devices")
                                                .font(.system(size: 13))
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(.secondary)
                                    }
                                    .foregroundStyle(.primary)
                                    .padding(16)
                                }

                                Divider()
                                    .padding(.leading, 60)
                            }

                            // Sign out button
                            Button(role: .destructive) {
                                showSignOutConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 18))
                                        .frame(width: 28)

                                    Text("Sign Out")
                                        .font(.system(size: 16, weight: .medium))

                                    Spacer()
                                }
                                .foregroundStyle(.red)
                                .padding(16)
                            }
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 20)

                        // Info section
                        if !isGuest {
                            VStack(alignment: .leading, spacing: 12) {
                                InfoRow(label: "Account Created", value: formattedDate(authService.currentUser?.createdAt))

                                if let lastSync = authService.currentUser?.lastSyncDate {
                                    InfoRow(label: "Last Synced", value: formattedDate(lastSync))
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                            )
                            .padding(.horizontal, 20)
                        }

                        Spacer()
                    }
                }

                // Loading overlay
                if authService.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(isGuest
                    ? "You'll need to sign in again to use the app."
                    : "Your phones will remain on this device but won't sync until you sign in again."
                )
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    ProfileView()
        .environment(AuthenticationService.shared)
}
