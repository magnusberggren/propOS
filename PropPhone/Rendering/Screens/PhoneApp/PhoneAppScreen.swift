//
//  PhoneAppScreen.swift
//  PropPhone
//
//  The Phone app replica: classic five-tab layout with a fully
//  functional Voicemail tab. Every tab responds so an actor can
//  navigate freely without breaking the illusion.
//

import SwiftUI

struct PhoneAppScreen: View {
    let runtime: PhoneRuntime
    let appState: PhoneAppState
    let displayTime: Date

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                IOSStatusBar(
                    style: .inApp,
                    spec: runtime.state.profile.statusBar,
                    time: displayTime,
                    tint: .primary
                )
                .padding(.horizontal, 20)
                .padding(.top, DeviceMetrics.top - 47)

                Group {
                    switch appState.tab {
                    case .favorites:
                        FavoritesTab(runtime: runtime)
                    case .recents:
                        RecentsTab(runtime: runtime, appState: appState)
                    case .contacts:
                        ContactsTab(runtime: runtime)
                    case .keypad:
                        KeypadTab(runtime: runtime, appState: appState)
                    case .voicemail:
                        VoicemailTab(runtime: runtime, appState: appState)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                PhoneTabBar(runtime: runtime, selected: appState.tab)
            }
        }
        .environment(\.colorScheme, .light)
        // Swipe up from the very bottom goes home, like the real thing.
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.startLocation.y > UIScreen.main.bounds.height - 44,
                       value.translation.height < -50 {
                        runtime.goHome()
                    }
                }
        )
    }
}

// MARK: - Tab bar

struct PhoneTabBar: View {
    let runtime: PhoneRuntime
    let selected: PhoneTab

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .top) {
                tabItem(.favorites, symbol: "star.fill", label: "Favorites")
                tabItem(.recents, symbol: "clock.fill", label: "Recents")
                tabItem(.contacts, symbol: "person.crop.circle", label: "Contacts")
                tabItem(.keypad, symbol: "circle.grid.3x3.fill", label: "Keypad")
                tabItem(.voicemail, symbol: "recordingtape", label: "Voicemail",
                        badge: runtime.state.unheardVoicemailCount)
            }
            .padding(.top, 6)

            Spacer(minLength: 0)

            HomeIndicator(tint: .black.opacity(0.85))
        }
        .frame(height: 49 + DeviceMetrics.bottom)
        .background(.bar)
    }

    private func tabItem(_ tab: PhoneTab, symbol: String, label: String, badge: Int = 0) -> some View {
        Button {
            runtime.selectTab(tab)
        } label: {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: symbol)
                        .font(.system(size: 22))
                        .frame(height: 26)

                    if badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5.5)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Circle().fill(.red))
                            .offset(x: 12, y: -6)
                    }
                }
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundStyle(selected == tab ? Color.accentBlue : Color(uiColor: .systemGray))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared bits

extension Color {
    /// iOS system blue as used across the Phone app.
    static let accentBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
}

/// Hand-rolled large-title header used by the Phone app tabs.
struct LargeTitleHeader<Leading: View, Trailing: View>: View {
    var title: String
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                leading
                Spacer()
                trailing
            }
            .font(.system(size: 17))
            .foregroundStyle(Color.accentBlue)
            .frame(height: 34)
            .padding(.horizontal, 16)

            Text(title)
                .font(.system(size: 34, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
        }
    }
}
