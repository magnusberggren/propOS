//
//  PropPhoneApp.swift
//  PropPhone
//
//  Created by Magnus Berggren on 11/12/2025.
//

import SwiftUI

@main
struct PropPhoneApp: App {
    @State private var appViewModel = AppViewModel()
    @State private var authService = AuthenticationService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appViewModel)
                .environment(authService)
        }
    }
}

struct RootView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(AuthenticationService.self) private var authService

    var body: some View {
        Group {
            if authService.isAuthenticated {
                // User is logged in - show main app
                if let mode = appViewModel.currentMode {
                    switch mode {
                    case .controller:
                        if let controllerVM = appViewModel.controllerVM {
                            ControllerMainView()
                                .environment(controllerVM)
                        }
                    case .mimic:
                        if let mimicVM = appViewModel.mimicVM {
                            MimicContainerView()
                                .environment(mimicVM)
                        }
                    case .demo:
                        DemoContainerView()
                    }
                } else {
                    ModeSelectionView()
                }
            } else {
                // User not logged in - show onboarding
                OnboardingView()
            }
        }
    }
}
