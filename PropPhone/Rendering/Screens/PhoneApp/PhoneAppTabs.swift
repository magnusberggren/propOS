//
//  PhoneAppTabs.swift
//  PropPhone
//
//  The supporting Phone app tabs: Favorites, Recents, Contacts and
//  Keypad. All interactive enough that an actor exploring the app
//  never hits a dead end.
//

import SwiftUI

// MARK: - Favorites

struct FavoritesTab: View {
    let runtime: PhoneRuntime

    var body: some View {
        VStack(spacing: 0) {
            LargeTitleHeader(title: "Favorites") {
                Image(systemName: "plus")
            } trailing: {
                Text("Edit")
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(favorites) { contact in
                        Button {
                            // Tapping a favorite places a call, like the real thing.
                            runtime.callBack(from: VoicemailMessage(contactID: contact.id))
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(
                                    name: contact.displayName,
                                    monogram: contact.monogram,
                                    imageAsset: contact.imageAsset,
                                    size: 44,
                                    assetGeneration: runtime.assetGeneration
                                )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.displayName)
                                        .font(.system(size: 17))
                                        .foregroundStyle(.primary)
                                    HStack(spacing: 4) {
                                        Image(systemName: "phone.fill")
                                            .font(.system(size: 11))
                                        Text(contact.numberLabel)
                                            .font(.system(size: 13))
                                    }
                                    .foregroundStyle(Color(uiColor: .systemGray))
                                }

                                Spacer()

                                Image(systemName: "info.circle")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Color.accentBlue)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 72)
                    }
                }
            }
        }
    }

    private var favorites: [ContactCard] {
        runtime.state.profile.favorites.compactMap { runtime.state.profile.contact($0) }
    }
}

// MARK: - Recents

struct RecentsTab: View {
    let runtime: PhoneRuntime
    let appState: PhoneAppState

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Edit")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.accentBlue)

                Spacer()

                Picker("", selection: Binding(
                    get: { appState.recentsShowsMissed },
                    set: { runtime.toggleRecentsMissed($0) }
                )) {
                    Text("All").tag(false)
                    Text("Missed").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 170)

                Spacer()

                Color.clear.frame(width: 34, height: 10)
            }
            .frame(height: 40)
            .padding(.horizontal, 16)

            HStack {
                Text("Recents")
                    .font(.system(size: 34, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(visibleCalls) { call in
                        RecentCallRow(runtime: runtime, call: call)
                        Divider().padding(.leading, 16)
                    }
                }
            }
        }
    }

    private var visibleCalls: [RecentCall] {
        appState.recentsShowsMissed
            ? runtime.state.profile.recents.filter(\.isMissed)
            : runtime.state.profile.recents
    }
}

struct RecentCallRow: View {
    let runtime: PhoneRuntime
    let call: RecentCall

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "phone.arrow.up.right.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color(uiColor: .systemGray))
                .opacity(call.isOutgoing ? 1 : 0)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(call.isMissed ? Color(red: 1.0, green: 0.23, blue: 0.19) : .primary)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Image(systemName: call.isFaceTime ? "video.fill" : "phone.fill")
                        .font(.system(size: 12))
                    Text(call.subtitle)
                        .font(.system(size: 15))
                }
                .foregroundStyle(Color(uiColor: .systemGray))
            }

            Spacer()

            Text(call.timeLabel)
                .font(.system(size: 15))
                .foregroundStyle(Color(uiColor: .systemGray))

            Image(systemName: "info.circle")
                .font(.system(size: 22))
                .foregroundStyle(Color.accentBlue)
                .padding(.leading, 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var displayName: String {
        runtime.state.profile.contact(call.contactID)?.displayName
            ?? (call.displayName.isEmpty ? "Unknown" : call.displayName)
    }
}

// MARK: - Contacts

struct ContactsTab: View {
    let runtime: PhoneRuntime

    var body: some View {
        VStack(spacing: 0) {
            LargeTitleHeader(title: "Contacts") {
                Text("Lists")
            } trailing: {
                Image(systemName: "plus")
            }

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(uiColor: .systemGray))
                Text("Search")
                    .font(.system(size: 17))
                    .foregroundStyle(Color(uiColor: .systemGray))
                Spacer()
                Image(systemName: "mic.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(uiColor: .systemGray))
            }
            .padding(.horizontal, 8)
            .frame(height: 36)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(uiColor: .systemGray6)))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(sections, id: \.letter) { section in
                        Section {
                            ForEach(section.contacts) { contact in
                                HStack {
                                    (Text(contact.givenName + " ")
                                     + Text(contact.familyName).fontWeight(.semibold))
                                        .font(.system(size: 17))
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 11)

                                Divider().padding(.leading, 16)
                            }
                        } header: {
                            HStack {
                                Text(section.letter)
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 3)
                            .background(Color(uiColor: .systemGray6))
                        }
                    }
                }
            }
            .overlay(alignment: .trailing) {
                VStack(spacing: 1.5) {
                    ForEach(sections, id: \.letter) { section in
                        Text(section.letter)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.accentBlue)
                    }
                }
                .padding(.trailing, 3)
            }
        }
    }

    private var sections: [(letter: String, contacts: [ContactCard])] {
        let sorted = runtime.state.profile.contacts.sorted {
            sortKey($0).localizedCaseInsensitiveCompare(sortKey($1)) == .orderedAscending
        }
        let grouped = Dictionary(grouping: sorted) { contact in
            String(sortKey(contact).prefix(1)).uppercased()
        }
        return grouped.keys.sorted().map { ($0, grouped[$0] ?? []) }
    }

    private func sortKey(_ c: ContactCard) -> String {
        c.familyName.isEmpty ? c.givenName : c.familyName
    }
}

// MARK: - Keypad

struct KeypadTab: View {
    let runtime: PhoneRuntime
    let appState: PhoneAppState

    private let keys: [(digit: String, letters: String)] = [
        ("1", ""), ("2", "A B C"), ("3", "D E F"),
        ("4", "G H I"), ("5", "J K L"), ("6", "M N O"),
        ("7", "P Q R S"), ("8", "T U V"), ("9", "W X Y Z"),
        ("*", ""), ("0", "+"), ("#", "")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 4) {
                Text(appState.keypadDigits.isEmpty ? " " : appState.keypadDigits)
                    .font(.system(size: 36, weight: .regular))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .frame(height: 44)
                    .padding(.horizontal, 40)

                Text("Add Number")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.accentBlue)
                    .opacity(appState.keypadDigits.isEmpty ? 0 : 1)
            }
            .padding(.bottom, 18)

            LazyVGrid(columns: [GridItem(.fixed(82)), GridItem(.fixed(82)), GridItem(.fixed(82))], spacing: 14) {
                ForEach(keys, id: \.digit) { key in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        runtime.keypadAppend(key.digit)
                    } label: {
                        ZStack {
                            Circle().fill(Color(uiColor: .systemGray5))
                            VStack(spacing: -1) {
                                Text(key.digit)
                                    .font(.system(size: 34, weight: .regular))
                                    .foregroundStyle(.primary)
                                if !key.letters.isEmpty {
                                    Text(key.letters)
                                        .font(.system(size: 10, weight: .semibold))
                                        .kerning(1)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                        .frame(width: 82, height: 82)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Color.clear.frame(width: 82, height: 82)

                Button {
                    // A prop phone never really dials — but the button must react.
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    ZStack {
                        Circle().fill(Color(red: 0.20, green: 0.78, blue: 0.29))
                        Image(systemName: "phone.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 82, height: 82)
                }
                .buttonStyle(.plain)

                Button {
                    runtime.keypadDeleteLast()
                } label: {
                    Image(systemName: "delete.left")
                        .font(.system(size: 26))
                        .foregroundStyle(Color(uiColor: .systemGray))
                        .frame(width: 82, height: 82)
                }
                .buttonStyle(.plain)
                .opacity(appState.keypadDigits.isEmpty ? 0 : 1)
            }
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
    }
}
