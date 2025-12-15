//
//  OnboardingView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @Environment(AuthenticationService.self) private var authService
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Background
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App icon and title
                VStack(spacing: 20) {
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 80))
                        .foregroundStyle(.primary)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                        )

                    Text("Prop Phone")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("Film & TV Production Tool")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Features list
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "rectangle.on.rectangle",
                        title: "Control Multiple Devices",
                        description: "Send calls, messages, and screen states to prop phones"
                    )

                    FeatureRow(
                        icon: "person.2.fill",
                        title: "Character Phones",
                        description: "Create unique phones with custom contacts for each character"
                    )

                    FeatureRow(
                        icon: "clock.fill",
                        title: "Time Control",
                        description: "Set and freeze time for continuity across takes"
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                // Sign in buttons
                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task {
                            do {
                                try await authService.signInWithApple()
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
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        authService.continueAsGuest()
                    } label: {
                        Text("Continue as Guest")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                    }

                    Text("Sign in to sync your phones across devices")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
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
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AuthenticationService.shared)
}
