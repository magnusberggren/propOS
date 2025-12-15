//
//  DemoContainerView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI
import PhotosUI

struct DemoContainerView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var currentScreen: DemoScreen = .menu

    // Editable state
    @State private var callerName: String = "Mom"
    @State private var callerNumber: String = "(555) 123-4567"
    @State private var callerIcon: String = "person.circle.fill"
    @State private var customCallerImage: UIImage? = nil
    @State private var isVideoCall: Bool = false

    @State private var notifications: [PropNotification] = [
        PropNotification(
            appName: "Messages",
            appIcon: "message.fill",
            title: "John Doe",
            body: "Hey, are you free for dinner tonight?",
            timestamp: Date().addingTimeInterval(-300),
            isUrgent: false
        ),
        PropNotification(
            appName: "Mail",
            appIcon: "envelope.fill",
            title: "Work Email",
            body: "Important update regarding the project",
            timestamp: Date().addingTimeInterval(-600),
            isUrgent: true
        )
    ]

    @State private var lockScreenTime: Date = Date()
    @State private var wallpaper: Wallpaper = .black
    @State private var customWallpaperImage: UIImage? = nil
    @State private var isFullscreen: Bool = false

    var body: some View {
        ZStack {
            // Display appropriate screen
            switch currentScreen {
            case .menu:
                DemoMenuView(
                    onSelectScreen: { screen in
                        currentScreen = screen
                    },
                    onEditCall: {
                        currentScreen = .editCall
                    },
                    onEditLockScreen: {
                        currentScreen = .editLockScreen
                    }
                )

            case .incomingCall:
                IncomingCallView(
                    call: CallState(
                        callerName: callerName,
                        callerNumber: callerNumber,
                        callerPhotoURL: callerIcon,
                        isVideo: isVideoCall
                    ),
                    customCallerImage: customCallerImage
                )
                .overlay(alignment: .topTrailing) {
                    if !isFullscreen {
                        ExitButton { currentScreen = .menu }
                    }
                }
                .overlay(alignment: .topLeading) {
                    if !isFullscreen {
                        FullscreenToggleButton(isFullscreen: $isFullscreen)
                    }
                }
                .onTapGesture(count: 2) {
                    // Double-tap to toggle fullscreen
                    isFullscreen.toggle()
                }

            case .lockScreen:
                LockScreenView(
                    time: lockScreenTime,
                    notifications: notifications,
                    signalStrength: 4,
                    carrierName: "Verizon",
                    batteryPercent: 85,
                    wallpaper: wallpaper,
                    customWallpaperImage: customWallpaperImage
                )
                .overlay(alignment: .topTrailing) {
                    if !isFullscreen {
                        ExitButton { currentScreen = .menu }
                    }
                }
                .overlay(alignment: .topLeading) {
                    if !isFullscreen {
                        FullscreenToggleButton(isFullscreen: $isFullscreen)
                    }
                }
                .onTapGesture(count: 2) {
                    // Double-tap to toggle fullscreen
                    isFullscreen.toggle()
                }

            case .editCall:
                EditCallView(
                    callerName: $callerName,
                    callerNumber: $callerNumber,
                    callerIcon: $callerIcon,
                    customCallerImage: $customCallerImage,
                    isVideoCall: $isVideoCall,
                    onPreview: {
                        currentScreen = .incomingCall
                    },
                    onBack: {
                        currentScreen = .menu
                    }
                )

            case .editLockScreen:
                EditLockScreenView(
                    notifications: $notifications,
                    lockScreenTime: $lockScreenTime,
                    wallpaper: $wallpaper,
                    customWallpaperImage: $customWallpaperImage,
                    onPreview: {
                        currentScreen = .lockScreen
                    },
                    onBack: {
                        currentScreen = .menu
                    }
                )

            case .lockScreenWithCall:
                IncomingCallView(
                    call: CallState(
                        callerName: callerName,
                        callerNumber: callerNumber,
                        callerPhotoURL: callerIcon,
                        isVideo: isVideoCall
                    ),
                    customCallerImage: customCallerImage
                )
                .overlay(alignment: .topTrailing) {
                    ExitButton { currentScreen = .menu }
                }
            }
        }
    }
}

enum DemoScreen {
    case menu
    case incomingCall
    case lockScreen
    case editCall
    case editLockScreen
    case lockScreenWithCall
}

struct DemoMenuView: View {
    @Environment(AppViewModel.self) private var appViewModel
    let onSelectScreen: (DemoScreen) -> Void
    let onEditCall: () -> Void
    let onEditLockScreen: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                // Light gray background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 14) {
                        Circle()
                            .fill(Color.black.opacity(0.04))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "sparkles.rectangle.stack.fill")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundColor(.purple)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                            )

                        Text("Demo Mode")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("Preview and customize your screens")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)

                    // Screen options
                    VStack(spacing: 12) {
                        DemoScreenButton(
                            icon: "phone.fill",
                            title: "Incoming Call",
                            description: "Customize caller info and preview",
                            color: .green,
                            showEdit: true
                        ) {
                            onSelectScreen(.incomingCall)
                        } onEdit: {
                            onEditCall()
                        }

                        DemoScreenButton(
                            icon: "lock.shield.fill",
                            title: "Lock Screen",
                            description: "Set wallpaper, time and notifications",
                            color: .blue,
                            showEdit: true
                        ) {
                            onSelectScreen(.lockScreen)
                        } onEdit: {
                            onEditLockScreen()
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // Back button
                    Button {
                        appViewModel.returnToModeSelection()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back to Mode Selection")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

struct DemoScreenButton: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    var showEdit: Bool = false
    let action: () -> Void
    var onEdit: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 14) {
                    // Icon with colored background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        )

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
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())

            if showEdit, let onEdit = onEdit {
                Button(action: onEdit) {
                    VStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Edit")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(color)
                    .frame(width: 60)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

struct EditCallView: View {
    @Binding var callerName: String
    @Binding var callerNumber: String
    @Binding var callerIcon: String
    @Binding var customCallerImage: UIImage?
    @Binding var isVideoCall: Bool
    let onPreview: () -> Void
    let onBack: () -> Void

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showTemplatesPicker: Bool = false
    @State private var showSaveTemplate: Bool = false

    private let templateService = TemplateStorageService.shared

    private let iconOptions = [
        "person.circle.fill",
        "person.crop.circle.fill",
        "person.2.circle.fill",
        "phone.circle.fill",
        "briefcase.circle.fill",
        "house.circle.fill"
    ]

    private var lightBackground: some View {
        Color(uiColor: .systemGroupedBackground)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Caller Name")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            TextField("Enter name", text: $callerName)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary)
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                )
        }
    }

    private var numberField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Caller Number")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            TextField("(555) 123-4567", text: $callerNumber)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary)
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                )
        }
    }

    private var photoPickerButton: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            HStack(spacing: 7) {
                Image(systemName: "photo.fill")
                Text("Choose Photo")
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue)
            .cornerRadius(10)
        }
    }

    private func iconButton(for icon: String) -> some View {
        let isSelected = callerIcon == icon

        return Button {
            callerIcon = icon
        } label: {
            Circle()
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.black.opacity(0.04))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(isSelected ? .blue : .primary.opacity(0.4))
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.06), lineWidth: 0.5)
                )
        }
    }

    @ViewBuilder
    private var customPhotoPreview: some View {
        if let customImage = customCallerImage {
            HStack(spacing: 14) {
                Image(uiImage: customImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.blue, lineWidth: 2)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Custom Photo")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    Button { customCallerImage = nil } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "trash.fill")
                            Text("Remove")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red)
                    }
                }
                Spacer()
            }
            .padding(12)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private var iconScrollView: some View {
        if customCallerImage == nil {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(iconOptions, id: \.self) { icon in
                        iconButton(for: icon)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var videoCallToggle: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "video.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Video Call")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text("Enable FaceTime style")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isVideoCall).labelsHidden().tint(.blue)
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var previewButton: some View {
        Button { onPreview() } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.circle.fill").font(.system(size: 20))
                Text("Preview Call Screen").font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.green)
            .cornerRadius(12)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                lightBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 20) {
                            // Header with templates button
                            HStack {
                                SectionHeader(title: "Caller Details", icon: "person.crop.circle.badge.plus")

                                Spacer()

                                Button {
                                    showTemplatesPicker = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 12, weight: .semibold))
                                        Text("Templates")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }

                            nameField
                            numberField

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Caller Photo")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                    Spacer()
                                    photoPickerButton
                                }
                                customPhotoPreview
                                iconScrollView
                            }

                            videoCallToggle

                            // Save as template button
                            if !callerName.isEmpty {
                                saveTemplateButton
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)

                        previewButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Call")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { onBack() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                            Text("Back").font(.system(size: 17, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        customCallerImage = uiImage
                    }
                }
            }
            .sheet(isPresented: $showTemplatesPicker) {
                CallTemplatePickerView(templateService: templateService) { template in
                    applyTemplate(template)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showSaveTemplate) {
                SaveCallTemplateSheet(
                    templateService: templateService,
                    callerName: callerName,
                    callerNumber: callerNumber.isEmpty ? nil : callerNumber,
                    callerIcon: callerIcon,
                    callerPhotoData: customCallerImage?.jpegData(compressionQuality: 0.7),
                    isVideo: isVideoCall
                )
                .presentationDetents([.medium])
            }
        }
    }

    private var saveTemplateButton: some View {
        Button {
            showSaveTemplate = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 14, weight: .semibold))
                Text("Save as Template")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.green)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func applyTemplate(_ template: CallTemplate) {
        callerName = template.callerName
        callerNumber = template.callerNumber ?? ""
        callerIcon = template.callerIcon
        isVideoCall = template.isVideo
        if let photoData = template.callerPhotoData {
            customCallerImage = UIImage(data: photoData)
        } else {
            customCallerImage = nil
        }
    }
}

struct EditLockScreenView: View {
    @Binding var notifications: [PropNotification]
    @Binding var lockScreenTime: Date
    @Binding var wallpaper: Wallpaper
    @Binding var customWallpaperImage: UIImage?
    let onPreview: () -> Void
    let onBack: () -> Void

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var editingNotificationIndex: Int?
    @State private var showNotificationTemplatesPicker = false
    @State private var showSaveNotificationTemplateSheet = false
    @State private var templateToSave: PropNotification?

    // Scene template states
    @State private var showSceneTemplatesPicker = false
    @State private var showSaveSceneTemplateSheet = false

    private let templateService = TemplateStorageService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Scene Templates section - prominent at top
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Scene Templates", icon: "rectangle.stack.fill")

                            HStack(spacing: 12) {
                                // Load template button
                                Button {
                                    showSceneTemplatesPicker = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "folder.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("Load Scene")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }

                                // Save template button
                                Button {
                                    showSaveSceneTemplateSheet = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.down.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("Save Scene")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.green)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.green.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)

                        // Date & Time section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Date & Time", icon: "clock.fill")

                            DatePicker("Display Date & Time", selection: $lockScreenTime, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .tint(.blue)
                        }
                        .padding(18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)

                        // Wallpaper section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                SectionHeader(title: "Wallpaper", icon: "photo.fill")

                                Spacer()

                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 12, weight: .semibold))
                                        Text("Custom")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }

                            // Custom wallpaper preview
                            if let customImage = customWallpaperImage {
                                HStack(spacing: 14) {
                                    Image(uiImage: customImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.blue, lineWidth: 2)
                                        )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Custom Photo")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)

                                        Button { customWallpaperImage = nil } label: {
                                            HStack(spacing: 5) {
                                                Image(systemName: "trash.fill")
                                                Text("Remove")
                                            }
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.red)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            // Preset wallpapers
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Wallpaper.allCases) { wp in
                                        WallpaperPreview(
                                            wallpaper: wp,
                                            isSelected: customWallpaperImage == nil && wallpaper == wp
                                        ) {
                                            wallpaper = wp
                                            customWallpaperImage = nil
                                        }
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)

                        // Notifications section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                SectionHeader(title: "Notifications", icon: "bell.badge.fill")

                                Spacer()

                                // Notification Templates button
                                Button {
                                    showNotificationTemplatesPicker = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 12, weight: .semibold))
                                        Text("Presets")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(.purple)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.purple.opacity(0.1))
                                    .clipShape(Capsule())
                                }

                                // Add button
                                Button { addNotification() } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                }
                            }

                            if notifications.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "bell.slash")
                                        .font(.system(size: 32))
                                        .foregroundColor(.secondary)
                                    Text("No notifications")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(Array(notifications.enumerated()), id: \.element.id) { index, notification in
                                        NotificationEditRow(
                                            notification: notification,
                                            onEdit: {
                                                editingNotificationIndex = index
                                            },
                                            onDelete: {
                                                removeNotification(notification)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)

                        // Preview button
                        Button { onPreview() } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 20))
                                Text("Preview Lock Screen")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Lock Screen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { onBack() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        customWallpaperImage = uiImage
                    }
                }
            }
            .sheet(item: $editingNotificationIndex) { index in
                EditNotificationSheet(
                    notification: $notifications[index],
                    onSaveAsTemplate: {
                        templateToSave = notifications[index]
                        showSaveNotificationTemplateSheet = true
                    }
                )
            }
            .sheet(isPresented: $showNotificationTemplatesPicker) {
                NotificationTemplatePickerView(templateService: templateService) { template in
                    let notification = template.toNotification()
                    notifications.append(notification)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showSaveNotificationTemplateSheet) {
                if let notif = templateToSave {
                    SaveNotificationTemplateSheet(
                        templateService: templateService,
                        appName: notif.appName,
                        appIcon: notif.appIcon,
                        title: notif.title,
                        messageBody: notif.body,
                        isUrgent: notif.isUrgent
                    )
                    .presentationDetents([.medium])
                }
            }
            .sheet(isPresented: $showSceneTemplatesPicker) {
                LockScreenTemplatePickerView(templateService: templateService) { template in
                    applySceneTemplate(template)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showSaveSceneTemplateSheet) {
                SaveLockScreenTemplateSheet(
                    templateService: templateService,
                    displayTime: lockScreenTime,
                    wallpaperName: wallpaper.rawValue,
                    wallpaperImageData: customWallpaperImage?.jpegData(compressionQuality: 0.7)
                )
                .presentationDetents([.medium])
            }
        }
    }

    private func addNotification() {
        let newNotification = PropNotification(
            appName: "Messages",
            appIcon: "message.fill",
            title: "New Message",
            body: "Tap edit to customize",
            timestamp: Date(),
            isUrgent: false
        )
        notifications.append(newNotification)
        // Automatically open edit sheet for the new notification
        editingNotificationIndex = notifications.count - 1
    }

    private func removeNotification(_ notification: PropNotification) {
        notifications.removeAll { $0.id == notification.id }
    }

    private func applySceneTemplate(_ template: LockScreenTemplate) {
        lockScreenTime = template.displayTime

        // Try to match wallpaper by name
        if let matchedWallpaper = Wallpaper.allCases.first(where: { $0.rawValue == template.wallpaperName }) {
            wallpaper = matchedWallpaper
            customWallpaperImage = nil
        } else if let imageData = template.wallpaperImageData,
                  let image = UIImage(data: imageData) {
            // Custom wallpaper
            customWallpaperImage = image
        }
    }
}

// Make Int conform to Identifiable for sheet binding
extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

struct NotificationEditRow: View {
    let notification: PropNotification
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // App icon
            Image(systemName: notification.appIcon)
                .font(.system(size: 20))
                .foregroundColor(.purple)
                .frame(width: 40, height: 40)
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.appName)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    if notification.isUrgent {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                    }
                }

                Text(notification.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text(notification.body)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
                    .frame(width: 36, height: 36)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
    }
}

// MARK: - Edit Notification Sheet

struct EditNotificationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var notification: PropNotification
    let onSaveAsTemplate: (() -> Void)?

    @State private var appName: String = ""
    @State private var appIcon: String = ""
    @State private var title: String = ""
    @State private var messageBody: String = ""
    @State private var timestamp: Date = Date()
    @State private var isUrgent: Bool = false

    private let templateService = TemplateStorageService.shared

    private let appPresets: [(name: String, icon: String)] = [
        ("Messages", "message.fill"),
        ("Mail", "envelope.fill"),
        ("Phone", "phone.fill"),
        ("Calendar", "calendar"),
        ("Photos", "photo.fill"),
        ("Weather", "cloud.sun.fill"),
        ("News", "newspaper.fill"),
        ("Emergency", "exclamationmark.triangle.fill")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // App selection
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "App", icon: "app.fill")

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(appPresets, id: \.name) { preset in
                                        appPresetButton(preset: preset)
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)

                        // Content
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Content", icon: "text.bubble.fill")

                            // Title field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title / Sender")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(0.5)

                                TextField("Enter title", text: $title)
                                    .font(.system(size: 16, weight: .medium))
                                    .padding(14)
                                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
                            }

                            // Message field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Message")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(0.5)

                                TextField("Enter message", text: $messageBody, axis: .vertical)
                                    .font(.system(size: 16, weight: .medium))
                                    .lineLimit(3...5)
                                    .padding(14)
                                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
                            }
                        }
                        .padding(18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)

                        // Time and options
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Options", icon: "slider.horizontal.3")

                            // Timestamp picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Time Received")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(0.5)

                                DatePicker("", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }

                            // Urgent toggle
                            HStack(spacing: 14) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.red)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Urgent")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.primary)

                                    Text("Red background highlight")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Toggle("", isOn: $isUrgent)
                                    .labelsHidden()
                                    .tint(.red)
                            }
                            .padding(12)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)

                        // Save as template button
                        if onSaveAsTemplate != nil {
                            Button {
                                saveChanges()
                                onSaveAsTemplate?()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Save as Template")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.purple)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        // Done button
                        Button {
                            saveChanges()
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Notification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadNotification()
            }
        }
    }

    private func appPresetButton(preset: (name: String, icon: String)) -> some View {
        let isSelected = appName == preset.name
        return Button {
            appName = preset.name
            appIcon = preset.icon
        } label: {
            VStack(spacing: 6) {
                Image(systemName: preset.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(isSelected ? .purple : .primary.opacity(0.4))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.purple.opacity(0.1) : Color.black.opacity(0.04))
                    )
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.purple.opacity(0.3) : Color.black.opacity(0.06), lineWidth: 0.5)
                    )

                Text(preset.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(width: 60)
        }
    }

    private func loadNotification() {
        appName = notification.appName
        appIcon = notification.appIcon
        title = notification.title
        messageBody = notification.body
        timestamp = notification.timestamp
        isUrgent = notification.isUrgent
    }

    private func saveChanges() {
        notification = PropNotification(
            id: notification.id,
            appName: appName,
            appIcon: appIcon,
            title: title,
            body: messageBody,
            timestamp: timestamp,
            isUrgent: isUrgent
        )
    }
}

struct ExitButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.8))
                .padding(20)
        }
    }
}

struct FullscreenToggleButton: View {
    @Binding var isFullscreen: Bool

    var body: some View {
        Button {
            isFullscreen.toggle()
        } label: {
            Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.8))
                .padding(20)
        }
    }
}

struct WallpaperPreview: View {
    let wallpaper: Wallpaper
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    wallpaper.background
                        .frame(width: 80, height: 140)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                        )

                    // Mini time preview
                    Text("9:41")
                        .font(.system(size: 24, weight: .thin))
                        .foregroundColor(.white)
                }

                Text(wallpaper.rawValue)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Section header component
struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.black.opacity(0.04))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                )

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

#Preview {
    DemoContainerView()
        .environment(AppViewModel())
}
