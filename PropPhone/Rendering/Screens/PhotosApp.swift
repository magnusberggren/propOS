//
//  PhotosApp.swift
//  PropPhone
//
//  The Photos replica: library grid of production-supplied images,
//  fullscreen viewer with paging and chrome toggle, and a believable
//  tab bar so wandering taps never dead-end.
//

import SwiftUI

struct PhotosAppScreen: View {
    let runtime: PhoneRuntime
    let appState: PhotosAppState
    let displayTime: Date

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                IOSStatusBar(
                    style: .inApp,
                    spec: runtime.state.profile.statusBar,
                    time: displayTime,
                    tint: appState.openPhotoIndex == nil ? .primary : .white
                )
                .padding(.horizontal, 20)
                .padding(.top, DeviceMetrics.top - 47)
                .zIndex(1)

                switch appState.tab {
                case .library:
                    PhotosLibraryView(runtime: runtime)
                case .forYou:
                    PhotosPlaceholderTab(title: "For You", subtitle: "Memories and shared photos appear here.")
                case .albums:
                    PhotosAlbumsView(runtime: runtime)
                case .search:
                    PhotosPlaceholderTab(title: "Search", subtitle: "Photos, people, and places.")
                }

                PhotosTabBar(runtime: runtime, selected: appState.tab)
            }

            if let index = appState.openPhotoIndex {
                PhotoViewer(runtime: runtime, index: index)
                    .transition(.opacity)
            }
        }
        .environment(\.colorScheme, appState.openPhotoIndex == nil ? .light : .dark)
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

// MARK: - Library grid

struct PhotosLibraryView: View {
    let runtime: PhoneRuntime

    private let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Photos")
                    .font(.system(size: 22, weight: .bold))
                Spacer()
                Text("Select")
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color(uiColor: .systemGray6)))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if runtime.state.profile.photos.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(uiColor: .systemGray2))
                    Text("No Photos")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color(uiColor: .systemGray))
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 1) {
                        ForEach(Array(runtime.state.profile.photos.enumerated()), id: \.offset) { index, spec in
                            Button {
                                runtime.openPhoto(at: index)
                            } label: {
                                PhotoCell(spec: spec, assetGeneration: runtime.assetGeneration)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

struct PhotoCell: View {
    let spec: ImageSpec
    var assetGeneration: Int

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                SpecImage(spec: spec, assetGeneration: assetGeneration)
                    .aspectRatio(contentMode: .fill)
            }
            .clipped()
            .contentShape(Rectangle())
    }
}

/// Renders an ImageSpec from the bundle or the asset store.
struct SpecImage: View {
    let spec: ImageSpec
    var assetGeneration: Int = 0

    var body: some View {
        Group {
            switch spec {
            case .builtin(let name):
                if UIImage(named: name) != nil {
                    Image(name).resizable()
                } else {
                    Color(uiColor: .systemGray5)
                }
            case .asset(let ref):
                if let image = AssetStore.shared.image(for: ref) {
                    Image(uiImage: image).resizable()
                } else {
                    Color(uiColor: .systemGray5)
                }
            }
        }
        .id(assetGeneration)
    }
}

// MARK: - Albums / placeholders

struct PhotosAlbumsView: View {
    let runtime: PhoneRuntime

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Albums")
                .font(.system(size: 34, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            HStack(spacing: 12) {
                if let first = runtime.state.profile.photos.first {
                    VStack(alignment: .leading, spacing: 4) {
                        SpecImage(spec: first, assetGeneration: runtime.assetGeneration)
                            .aspectRatio(1, contentMode: .fill)
                            .frame(width: 170, height: 170)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        Text("Recents")
                            .font(.system(size: 15))
                        Text("\(runtime.state.profile.photos.count)")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(uiColor: .systemGray))
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PhotosPlaceholderTab: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 34, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Spacer()
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundStyle(Color(uiColor: .systemGray))
            Spacer()
        }
    }
}

// MARK: - Tab bar

struct PhotosTabBar: View {
    let runtime: PhoneRuntime
    let selected: PhotosTab

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                tabItem(.library, symbol: "photo.on.rectangle", label: "Library")
                tabItem(.forYou, symbol: "heart.text.square", label: "For You")
                tabItem(.albums, symbol: "square.stack", label: "Albums")
                tabItem(.search, symbol: "magnifyingglass", label: "Search")
            }
            .padding(.top, 6)

            Spacer(minLength: 0)

            HomeIndicator(tint: .black.opacity(0.85))
        }
        .frame(height: 49 + DeviceMetrics.bottom)
        .background(.bar)
    }

    private func tabItem(_ tab: PhotosTab, symbol: String, label: String) -> some View {
        Button {
            runtime.selectPhotosTab(tab)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 22))
                    .frame(height: 26)
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundStyle(selected == tab ? Color.accentBlue : Color(uiColor: .systemGray))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Fullscreen viewer

struct PhotoViewer: View {
    let runtime: PhoneRuntime
    let index: Int

    @State private var chromeHidden = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: Binding(
                get: { index },
                set: { runtime.setOpenPhotoIndex($0) }
            )) {
                ForEach(Array(runtime.state.profile.photos.enumerated()), id: \.offset) { i, spec in
                    SpecImage(spec: spec, assetGeneration: runtime.assetGeneration)
                        .aspectRatio(contentMode: .fit)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) { chromeHidden.toggle() }
            }

            if !chromeHidden {
                VStack {
                    HStack {
                        Button {
                            runtime.closePhotoViewer()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 21, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text("\(index + 1) of \(runtime.state.profile.photos.count)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)

                        Spacer()

                        Color.clear.frame(width: 44, height: 44)
                    }
                    .padding(.top, DeviceMetrics.top + 2)
                    .background(.black.opacity(0.55))

                    Spacer()

                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Spacer()
                        Image(systemName: "heart")
                        Spacer()
                        Image(systemName: "info.circle")
                        Spacer()
                        Image(systemName: "trash")
                    }
                    .font(.system(size: 21))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.top, 12)
                    .padding(.bottom, DeviceMetrics.bottom + 8)
                    .background(.black.opacity(0.55))
                }
                .ignoresSafeArea()
            }
        }
    }
}
