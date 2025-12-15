//
//  NotificationControlView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

struct NotificationControlView: View {
    @Environment(ControllerViewModel.self) private var controllerVM
    @State private var appName: String = "Messages"
    @State private var title: String = ""
    @State private var messageBody: String = ""
    @State private var isUrgent: Bool = false
    @State private var selectedIcon: String = "message.fill"
    @State private var showTemplatesPicker: Bool = false
    @State private var showSaveTemplate: Bool = false
    @FocusState private var focusedField: Field?

    private let templateService = TemplateStorageService.shared

    private enum Field {
        case title, message
    }

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
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.black.opacity(0.04))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.purple)
                    )

                Text("Lock Screen Notification")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

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
                    .foregroundColor(.purple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            VStack(spacing: 18) {
                // App preset picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("App")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(appPresets, id: \.name) { preset in
                                appPresetButton(preset: preset)
                            }
                        }
                    }
                }

                // Title field
                glassTextField(
                    label: "Title",
                    placeholder: "Enter title",
                    text: $title,
                    isFocused: focusedField == .title
                )
                .focused($focusedField, equals: .title)
                .onTapGesture { focusedField = .title }

                // Message field
                glassTextField(
                    label: "Message",
                    placeholder: "Enter message",
                    text: $messageBody,
                    isFocused: focusedField == .message,
                    isMultiline: true
                )
                .focused($focusedField, equals: .message)
                .onTapGesture { focusedField = .message }

                // Urgent toggle
                urgentToggle

                // Save as template button
                if !title.isEmpty && !messageBody.isEmpty {
                    saveTemplateButton
                }

                // Action buttons
                HStack(spacing: 12) {
                    sendButton
                    clearButton
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        .sheet(isPresented: $showTemplatesPicker) {
            NotificationTemplatePickerView(templateService: templateService) { template in
                applyTemplate(template)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSaveTemplate) {
            SaveNotificationTemplateSheet(
                templateService: templateService,
                appName: appName,
                appIcon: selectedIcon,
                title: title,
                messageBody: messageBody,
                isUrgent: isUrgent
            )
            .presentationDetents([.medium])
        }
    }

    private func appPresetButton(preset: (name: String, icon: String)) -> some View {
        let isSelected = appName == preset.name
        return Button {
            appName = preset.name
            selectedIcon = preset.icon
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

    private func glassTextField(label: String, placeholder: String, text: Binding<String>, isFocused: Bool, isMultiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            if isMultiline {
                TextField(placeholder, text: text, axis: .vertical)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(3...5)
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isFocused ? Color.purple.opacity(0.5) : Color.black.opacity(0.06), lineWidth: 0.5)
                    )
            } else {
                TextField(placeholder, text: text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isFocused ? Color.purple.opacity(0.5) : Color.black.opacity(0.06), lineWidth: 0.5)
                    )
            }
        }
    }

    private var urgentToggle: some View {
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

    private var sendButton: some View {
        let isDisabled = title.isEmpty || messageBody.isEmpty
        return Button { sendNotification() } label: {
            HStack(spacing: 8) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("Send")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isDisabled ? Color.gray.opacity(0.3) : Color.blue)
            .cornerRadius(10)
        }
        .disabled(isDisabled)
    }

    private var clearButton: some View {
        Button { clearNotifications() } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("Clear All")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red)
            .cornerRadius(10)
        }
    }

    private func sendNotification() {
        let notification = PropNotification(
            appName: appName,
            appIcon: selectedIcon,
            title: title,
            body: messageBody,
            isUrgent: isUrgent
        )
        controllerVM.addNotification(notification)
        controllerVM.switchToLockScreen()
        title = ""
        messageBody = ""
        isUrgent = false
    }

    private func clearNotifications() {
        controllerVM.clearAllNotifications()
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
            .foregroundColor(.purple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.purple.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func applyTemplate(_ template: NotificationTemplate) {
        appName = template.appName
        selectedIcon = template.appIcon
        title = template.title
        messageBody = template.body
        isUrgent = template.isUrgent
    }
}

#Preview {
    ZStack {
        AppGradients.cosmicBackground.ignoresSafeArea()
        NotificationControlView()
            .padding()
            .environment(ControllerViewModel(multipeerService: MultipeerService(mode: .controller)))
    }
}
