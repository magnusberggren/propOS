//
//  PropPhoneApp.swift
//  PropPhone
//
//  Entry point. No accounts, no gates: pick a role and shoot.
//    Prop Phone — this device becomes a character's phone.
//    Controller — this device runs the show.
//    Solo — phone + controls on one device (single-phone scenes).
//

import SwiftUI

@main
struct PropPhoneApp: App {
    @State private var store = ShowStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}

enum AppRole: String {
    case none = ""
    case phone
    case controller
    case solo
}

struct RootView: View {
    @AppStorage("appRole") private var roleRaw = ""
    @Environment(ShowStore.self) private var store

    var body: some View {
        switch AppRole(rawValue: roleRaw) ?? .none {
        case .none:
            RolePickerView()
        case .phone:
            PhoneModeView()
        case .controller:
            ControllerHome()
        case .solo:
            SoloModeView()
        }
    }
}

// MARK: - Role picker

struct RolePickerView: View {
    @AppStorage("appRole") private var roleRaw = ""

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 44, weight: .light))
                Text("PropOS")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("Phone screens for film sets")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 26)

            RoleCard(
                title: "Prop Phone",
                subtitle: "This device is a character's phone. It renders scenes and follows the controller.",
                symbol: "iphone.gen3",
                color: .green
            ) { roleRaw = AppRole.phone.rawValue }

            RoleCard(
                title: "Controller",
                subtitle: "Run the show: build phones, load scenes, fire cues, reset between takes.",
                symbol: "slider.horizontal.3",
                color: .blue
            ) { roleRaw = AppRole.controller.rawValue }

            RoleCard(
                title: "Solo",
                subtitle: "Phone and controls on one device — for single-phone scenes without a second operator.",
                symbol: "person.fill",
                color: .orange
            ) { roleRaw = AppRole.solo.rawValue }
        }
        .padding(24)
        .frame(maxWidth: 500)
    }
}

struct RoleCard: View {
    let title: String
    let subtitle: String
    let symbol: String
    let color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
                    .frame(width: 46, height: 46)
                    .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
