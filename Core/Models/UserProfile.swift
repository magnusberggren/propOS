//
//  UserProfile.swift
//  PropPhone
//
//  User profile and authentication models
//

import Foundation
import AuthenticationServices

// MARK: - User Profile

struct UserProfile: Codable, Identifiable {
    var id: UUID
    var appleUserID: String?  // Apple's user identifier
    var username: String
    var email: String?
    var createdAt: Date
    var isPremium: Bool

    // Cloud sync status
    var lastSyncDate: Date?
    var syncEnabled: Bool

    init(
        id: UUID = UUID(),
        appleUserID: String? = nil,
        username: String,
        email: String? = nil,
        createdAt: Date = Date(),
        isPremium: Bool = false,
        lastSyncDate: Date? = nil,
        syncEnabled: Bool = false
    ) {
        self.id = id
        self.appleUserID = appleUserID
        self.username = username
        self.email = email
        self.createdAt = createdAt
        self.isPremium = isPremium
        self.lastSyncDate = lastSyncDate
        self.syncEnabled = syncEnabled
    }
}

// MARK: - Authentication Service

@Observable
class AuthenticationService: NSObject {
    static let shared = AuthenticationService()

    var currentUser: UserProfile?
    var isAuthenticated: Bool { currentUser != nil }
    var authError: AuthenticationError?
    var isLoading: Bool = false

    private var authContinuation: CheckedContinuation<ASAuthorization, Error>?

    private override init() {
        super.init()
        loadUser()
        checkAppleSignInState()
    }

    // MARK: - Apple Sign In

    @MainActor
    func signInWithApple() async throws {
        isLoading = true
        authError = nil

        defer { isLoading = false }

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let authController = ASAuthorizationController(authorizationRequests: [request])
        authController.delegate = self

        let authorization = try await withCheckedThrowingContinuation { continuation in
            self.authContinuation = continuation
            authController.performRequests()
        }

        try await handleAuthorization(authorization)
    }

    private func handleAuthorization(_ authorization: ASAuthorization) async throws {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthenticationError.invalidCredentials
        }

        let userID = credential.user

        // Get name from credential (only provided on first sign-in)
        var displayName = "User"
        if let fullName = credential.fullName {
            let givenName = fullName.givenName ?? ""
            let familyName = fullName.familyName ?? ""
            let name = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
            if !name.isEmpty {
                displayName = name
                // Save the name for future logins
                UserDefaults.standard.set(name, forKey: "appleUserDisplayName_\(userID)")
            }
        }

        // If no name from credential, try to get saved name
        if displayName == "User" {
            if let savedName = UserDefaults.standard.string(forKey: "appleUserDisplayName_\(userID)") {
                displayName = savedName
            }
        }

        // Get email (only provided on first sign-in)
        var email = credential.email
        if email == nil {
            email = UserDefaults.standard.string(forKey: "appleUserEmail_\(userID)")
        } else {
            UserDefaults.standard.set(email, forKey: "appleUserEmail_\(userID)")
        }

        // Create or update user profile
        let user = UserProfile(
            appleUserID: userID,
            username: displayName,
            email: email,
            isPremium: false
        )

        await MainActor.run {
            self.currentUser = user
            self.saveUser()
        }
    }

    // MARK: - Check Sign In State

    func checkAppleSignInState() {
        guard let appleUserID = currentUser?.appleUserID else { return }

        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: appleUserID) { [weak self] state, error in
            DispatchQueue.main.async {
                switch state {
                case .authorized:
                    // User is still authorized
                    break
                case .revoked, .notFound:
                    // User revoked authorization or not found - sign out
                    self?.signOut()
                case .transferred:
                    // User transferred to a different iCloud account
                    self?.signOut()
                @unknown default:
                    break
                }
            }
        }
    }

    // MARK: - Sign Out

    func signOut() {
        currentUser = nil
        saveUser()
    }

    // MARK: - Skip Auth (Guest Mode)

    func continueAsGuest() {
        let guestUser = UserProfile(
            username: "Guest",
            isPremium: false
        )
        currentUser = guestUser
        saveUser()
    }

    // MARK: - Persistence

    private func loadUser() {
        guard let data = UserDefaults.standard.data(forKey: "currentUser"),
              let user = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return
        }
        currentUser = user
    }

    private func saveUser() {
        if let user = currentUser,
           let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "currentUser")
        } else {
            UserDefaults.standard.removeObject(forKey: "currentUser")
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthenticationService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        authContinuation?.resume(returning: authorization)
        authContinuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                self.authContinuation?.resume(throwing: AuthenticationError.canceled)
            case .failed:
                self.authContinuation?.resume(throwing: AuthenticationError.failed)
            case .invalidResponse:
                self.authContinuation?.resume(throwing: AuthenticationError.invalidCredentials)
            case .notHandled:
                self.authContinuation?.resume(throwing: AuthenticationError.notHandled)
            case .unknown:
                self.authContinuation?.resume(throwing: AuthenticationError.unknown)
            case .notInteractive:
                self.authContinuation?.resume(throwing: AuthenticationError.notInteractive)
            @unknown default:
                self.authContinuation?.resume(throwing: AuthenticationError.unknown)
            }
        } else {
            self.authContinuation?.resume(throwing: AuthenticationError.unknown)
        }
        authContinuation = nil
    }
}

// MARK: - Authentication Errors

enum AuthenticationError: Error, LocalizedError {
    case canceled
    case failed
    case invalidCredentials
    case notHandled
    case notInteractive
    case unknown
    case networkError

    var errorDescription: String? {
        switch self {
        case .canceled:
            return "Sign in was canceled"
        case .failed:
            return "Sign in failed. Please try again."
        case .invalidCredentials:
            return "Invalid credentials"
        case .notHandled:
            return "Sign in request was not handled"
        case .notInteractive:
            return "Sign in requires user interaction"
        case .unknown:
            return "An unknown error occurred"
        case .networkError:
            return "Network error. Please check your connection."
        }
    }
}
