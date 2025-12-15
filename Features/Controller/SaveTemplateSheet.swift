//
//  SaveTemplateSheet.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

// MARK: - Save Call Template Sheet

struct SaveCallTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    let templateService: TemplateStorageService

    let callerName: String
    let callerNumber: String?
    let callerIcon: String
    let callerPhotoData: Data?
    let isVideo: Bool

    @State private var templateName: String = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview
                VStack(spacing: 16) {
                    Text("Template Preview")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 14) {
                        if let photoData = callerPhotoData,
                           let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: callerIcon)
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .frame(width: 50, height: 50)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(callerName)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)

                            if let number = callerNumber, !number.isEmpty {
                                Text(number)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if isVideo {
                            Image(systemName: "video.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Template Name")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    TextField("e.g., Work Call, Mom", text: $templateName)
                        .font(.system(size: 16, weight: .medium))
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isNameFocused ? Color.blue.opacity(0.5) : Color.black.opacity(0.06), lineWidth: 0.5)
                        )
                        .focused($isNameFocused)
                }

                Spacer()

                // Save button
                Button {
                    saveTemplate()
                } label: {
                    Text("Save Template")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(templateName.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(templateName.isEmpty)
            }
            .padding(20)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Save Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isNameFocused = true
            }
        }
    }

    private func saveTemplate() {
        let template = CallTemplate(
            name: templateName,
            callerName: callerName,
            callerNumber: callerNumber,
            callerPhotoData: callerPhotoData,
            callerIcon: callerIcon,
            isVideo: isVideo
        )
        templateService.addCallTemplate(template)
        dismiss()
    }
}

// MARK: - Save Notification Template Sheet

struct SaveNotificationTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    let templateService: TemplateStorageService

    let appName: String
    let appIcon: String
    let title: String
    let messageBody: String
    let isUrgent: Bool

    @State private var templateName: String = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview
                VStack(spacing: 16) {
                    Text("Template Preview")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 14) {
                        Image(systemName: appIcon)
                            .font(.system(size: 24))
                            .foregroundColor(.purple)
                            .frame(width: 50, height: 50)
                            .background(Color.purple.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(appName)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Text(title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Text(messageBody)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        if isUrgent {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Template Name")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    TextField("e.g., Urgent Alert, Meeting Reminder", text: $templateName)
                        .font(.system(size: 16, weight: .medium))
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isNameFocused ? Color.purple.opacity(0.5) : Color.black.opacity(0.06), lineWidth: 0.5)
                        )
                        .focused($isNameFocused)
                }

                Spacer()

                // Save button
                Button {
                    saveTemplate()
                } label: {
                    Text("Save Template")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(templateName.isEmpty ? Color.gray.opacity(0.3) : Color.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(templateName.isEmpty)
            }
            .padding(20)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Save Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isNameFocused = true
            }
        }
    }

    private func saveTemplate() {
        let template = NotificationTemplate(
            name: templateName,
            appName: appName,
            appIcon: appIcon,
            title: title,
            body: messageBody,
            isUrgent: isUrgent
        )
        templateService.addNotificationTemplate(template)
        dismiss()
    }
}

// MARK: - Save Lock Screen Scene Template Sheet

struct SaveLockScreenTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    let templateService: TemplateStorageService

    let displayTime: Date
    let wallpaperName: String
    let wallpaperImageData: Data?

    @State private var templateName: String = ""
    @FocusState private var isNameFocused: Bool

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview
                VStack(spacing: 16) {
                    Text("Scene Preview")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 14) {
                        // Time preview
                        VStack(alignment: .leading, spacing: 2) {
                            Text(timeFormatter.string(from: displayTime))
                                .font(.system(size: 28, weight: .light))
                                .foregroundColor(.primary)

                            Text(dateFormatter.string(from: displayTime))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Wallpaper indicator
                        HStack(spacing: 6) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 12))
                            Text(wallpaperImageData != nil ? "Custom" : wallpaperName)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Template Name")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    TextField("e.g., Morning Scene, Night Shot", text: $templateName)
                        .font(.system(size: 16, weight: .medium))
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isNameFocused ? Color.blue.opacity(0.5) : Color.black.opacity(0.06), lineWidth: 0.5)
                        )
                        .focused($isNameFocused)
                }

                Spacer()

                // Save button
                Button {
                    saveTemplate()
                } label: {
                    Text("Save Scene Template")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(templateName.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(templateName.isEmpty)
            }
            .padding(20)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Save Scene Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isNameFocused = true
            }
        }
    }

    private func saveTemplate() {
        let template = LockScreenTemplate(
            name: templateName,
            displayTime: displayTime,
            wallpaperName: wallpaperName,
            wallpaperImageData: wallpaperImageData
        )
        templateService.addLockScreenTemplate(template)
        dismiss()
    }
}

#Preview("Save Call") {
    SaveCallTemplateSheet(
        templateService: TemplateStorageService.shared,
        callerName: "John Doe",
        callerNumber: "(555) 123-4567",
        callerIcon: "person.circle.fill",
        callerPhotoData: nil,
        isVideo: false
    )
}

#Preview("Save Notification") {
    SaveNotificationTemplateSheet(
        templateService: TemplateStorageService.shared,
        appName: "Messages",
        appIcon: "message.fill",
        title: "New Message",
        messageBody: "Hey, are you coming to the party?",
        isUrgent: false
    )
}

#Preview("Save Lock Screen") {
    SaveLockScreenTemplateSheet(
        templateService: TemplateStorageService.shared,
        displayTime: Date(),
        wallpaperName: "Gradient",
        wallpaperImageData: nil
    )
}
