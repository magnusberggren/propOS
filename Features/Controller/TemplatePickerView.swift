//
//  TemplatePickerView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

// MARK: - Call Template Picker

struct CallTemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let templateService: TemplateStorageService
    let onSelect: (CallTemplate) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if templateService.callTemplates.isEmpty {
                    emptyState
                } else {
                    templateList
                }
            }
            .navigationTitle("Call Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "phone.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Templates")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Save a call configuration as a template to quickly reuse it later.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var templateList: some View {
        List {
            ForEach(templateService.callTemplates) { template in
                CallTemplateRow(template: template)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(template)
                        dismiss()
                    }
            }
            .onDelete { offsets in
                templateService.deleteCallTemplate(at: offsets)
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct CallTemplateRow: View {
    let template: CallTemplate

    var body: some View {
        HStack(spacing: 14) {
            // Icon or photo
            if let photoData = template.callerPhotoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                Image(systemName: template.callerIcon)
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Text(template.callerName)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    if template.isVideo {
                        Image(systemName: "video.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Notification Template Picker

struct NotificationTemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let templateService: TemplateStorageService
    let onSelect: (NotificationTemplate) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if templateService.notificationTemplates.isEmpty {
                    emptyState
                } else {
                    templateList
                }
            }
            .navigationTitle("Notification Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.badge")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Templates")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Save a notification as a template to quickly reuse it later.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var templateList: some View {
        List {
            ForEach(templateService.notificationTemplates) { template in
                NotificationTemplateRow(template: template)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(template)
                        dismiss()
                    }
            }
            .onDelete { offsets in
                templateService.deleteNotificationTemplate(at: offsets)
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct NotificationTemplateRow: View {
    let template: NotificationTemplate

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: template.appIcon)
                .font(.system(size: 22))
                .foregroundColor(.purple)
                .frame(width: 44, height: 44)
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Text(template.appName)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    if template.isUrgent {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Lock Screen Scene Template Picker

struct LockScreenTemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let templateService: TemplateStorageService
    let onSelect: (LockScreenTemplate) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if templateService.lockScreenTemplates.isEmpty {
                    emptyState
                } else {
                    templateList
                }
            }
            .navigationTitle("Scene Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Scene Templates")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Save a complete lock screen setup (date, wallpaper, notifications) to quickly load it later.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var templateList: some View {
        List {
            ForEach(templateService.lockScreenTemplates) { template in
                LockScreenTemplateRow(template: template)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(template)
                        dismiss()
                    }
            }
            .onDelete { offsets in
                templateService.deleteLockScreenTemplate(at: offsets)
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct LockScreenTemplateRow: View {
    let template: LockScreenTemplate

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }

    var body: some View {
        HStack(spacing: 14) {
            // Scene preview icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 70)

                VStack(spacing: 4) {
                    Text(timeFormatter.string(from: template.displayTime))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue.opacity(0.7))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Text(dateFormatter.string(from: template.displayTime))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(template.wallpaperName)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
}

#Preview("Call Templates") {
    CallTemplatePickerView(
        templateService: TemplateStorageService.shared,
        onSelect: { _ in }
    )
}

#Preview("Notification Templates") {
    NotificationTemplatePickerView(
        templateService: TemplateStorageService.shared,
        onSelect: { _ in }
    )
}

#Preview("Lock Screen Templates") {
    LockScreenTemplatePickerView(
        templateService: TemplateStorageService.shared,
        onSelect: { _ in }
    )
}
