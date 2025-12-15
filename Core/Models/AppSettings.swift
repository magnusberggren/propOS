//
//  AppSettings.swift
//  PropPhone
//
//  App-wide settings with @AppStorage persistence
//

import SwiftUI

@Observable
class AppSettings {
    static let shared = AppSettings()

    // MARK: - General Settings

    @AppStorage("defaultWallpaper") var defaultWallpaper: String = "black"
    @AppStorage("appTheme") var appThemeRawValue: String = AppTheme.system.rawValue
    @AppStorage("enableHapticFeedback") var enableHapticFeedback: Bool = true

    var appTheme: AppTheme {
        get { AppTheme(rawValue: appThemeRawValue) ?? .system }
        set { appThemeRawValue = newValue.rawValue }
    }

    // MARK: - Controller Settings

    @AppStorage("autoConnectToDevices") var autoConnectToDevices: Bool = false
    @AppStorage("defaultFreezeTime") var defaultFreezeTime: Bool = false
    @AppStorage("sendToAllDevicesByDefault") var sendToAllDevicesByDefault: Bool = true
    @AppStorage("showConnectionStatus") var showConnectionStatus: Bool = true

    // MARK: - Mimic Settings

    @AppStorage("mimicAlwaysOnDisplay") var mimicAlwaysOnDisplay: Bool = false
    @AppStorage("mimicShowStatusBar") var mimicShowStatusBar: Bool = true
    @AppStorage("mimicBatteryLevel") var mimicBatteryLevel: Int = 85
    @AppStorage("mimicSignalStrength") var mimicSignalStrength: Int = 4
    @AppStorage("mimicCarrierName") var mimicCarrierName: String = "Verizon"

    // MARK: - Demo Settings

    @AppStorage("demoAutoPreview") var demoAutoPreview: Bool = false
    @AppStorage("demoStartInFullscreen") var demoStartInFullscreen: Bool = false
    @AppStorage("demoShowEditHints") var demoShowEditHints: Bool = true

    // MARK: - Onboarding

    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("onboardingVersion") var onboardingVersion: String = ""

    // MARK: - Advanced

    @AppStorage("enableDebugMode") var enableDebugMode: Bool = false
    @AppStorage("showNetworkLogs") var showNetworkLogs: Bool = false
    @AppStorage("enablePerformanceMonitoring") var enablePerformanceMonitoring: Bool = false

    // MARK: - Lifecycle

    private init() {}

    /// Reset all settings to defaults
    func resetToDefaults() {
        defaultWallpaper = "black"
        appTheme = .system
        enableHapticFeedback = true

        autoConnectToDevices = false
        defaultFreezeTime = false
        sendToAllDevicesByDefault = true
        showConnectionStatus = true

        mimicAlwaysOnDisplay = false
        mimicShowStatusBar = true
        mimicBatteryLevel = 85
        mimicSignalStrength = 4
        mimicCarrierName = "Verizon"

        demoAutoPreview = false
        demoStartInFullscreen = false
        demoShowEditHints = true

        enableDebugMode = false
        showNetworkLogs = false
        enablePerformanceMonitoring = false
    }
}

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Codable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }

    var description: String {
        switch self {
        case .light: return "Always use light mode"
        case .dark: return "Always use dark mode"
        case .system: return "Match system appearance"
        }
    }
}
