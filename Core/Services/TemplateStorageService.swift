//
//  TemplateStorageService.swift
//  PropPhone
//
//  Created by Claude Code
//

import Foundation
import SwiftUI

@Observable
final class TemplateStorageService {
    static let shared = TemplateStorageService()

    private(set) var callTemplates: [CallTemplate] = []
    private(set) var notificationTemplates: [NotificationTemplate] = []
    private(set) var lockScreenTemplates: [LockScreenTemplate] = []

    private let fileManager = FileManager.default

    private var templatesDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("templates", isDirectory: true)
    }

    private var photosDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("photos", isDirectory: true)
    }

    private var callTemplatesFile: URL {
        templatesDirectory.appendingPathComponent("call_templates.json")
    }

    private var notificationTemplatesFile: URL {
        templatesDirectory.appendingPathComponent("notification_templates.json")
    }

    private var lockScreenTemplatesFile: URL {
        templatesDirectory.appendingPathComponent("lockscreen_templates.json")
    }

    init() {
        createDirectoriesIfNeeded()
        loadAllTemplates()
    }

    // MARK: - Directory Management

    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: templatesDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Call Templates

    func loadAllTemplates() {
        loadCallTemplates()
        loadNotificationTemplates()
        loadLockScreenTemplates()
    }

    private func loadCallTemplates() {
        guard fileManager.fileExists(atPath: callTemplatesFile.path) else {
            callTemplates = []
            return
        }

        do {
            let data = try Data(contentsOf: callTemplatesFile)
            callTemplates = try JSONDecoder().decode([CallTemplate].self, from: data)
        } catch {
            print("Failed to load call templates: \(error)")
            callTemplates = []
        }
    }

    private func saveCallTemplates() {
        do {
            let data = try JSONEncoder().encode(callTemplates)
            try data.write(to: callTemplatesFile)
        } catch {
            print("Failed to save call templates: \(error)")
        }
    }

    func addCallTemplate(_ template: CallTemplate) {
        callTemplates.append(template)
        saveCallTemplates()
    }

    func updateCallTemplate(_ template: CallTemplate) {
        if let index = callTemplates.firstIndex(where: { $0.id == template.id }) {
            var updated = template
            updated.updatedAt = Date()
            callTemplates[index] = updated
            saveCallTemplates()
        }
    }

    func deleteCallTemplate(_ template: CallTemplate) {
        callTemplates.removeAll { $0.id == template.id }
        saveCallTemplates()
    }

    func deleteCallTemplate(at offsets: IndexSet) {
        callTemplates.remove(atOffsets: offsets)
        saveCallTemplates()
    }

    // MARK: - Notification Templates

    private func loadNotificationTemplates() {
        guard fileManager.fileExists(atPath: notificationTemplatesFile.path) else {
            notificationTemplates = []
            return
        }

        do {
            let data = try Data(contentsOf: notificationTemplatesFile)
            notificationTemplates = try JSONDecoder().decode([NotificationTemplate].self, from: data)
        } catch {
            print("Failed to load notification templates: \(error)")
            notificationTemplates = []
        }
    }

    private func saveNotificationTemplates() {
        do {
            let data = try JSONEncoder().encode(notificationTemplates)
            try data.write(to: notificationTemplatesFile)
        } catch {
            print("Failed to save notification templates: \(error)")
        }
    }

    func addNotificationTemplate(_ template: NotificationTemplate) {
        notificationTemplates.append(template)
        saveNotificationTemplates()
    }

    func updateNotificationTemplate(_ template: NotificationTemplate) {
        if let index = notificationTemplates.firstIndex(where: { $0.id == template.id }) {
            var updated = template
            updated.updatedAt = Date()
            notificationTemplates[index] = updated
            saveNotificationTemplates()
        }
    }

    func deleteNotificationTemplate(_ template: NotificationTemplate) {
        notificationTemplates.removeAll { $0.id == template.id }
        saveNotificationTemplates()
    }

    func deleteNotificationTemplate(at offsets: IndexSet) {
        notificationTemplates.remove(atOffsets: offsets)
        saveNotificationTemplates()
    }

    // MARK: - Lock Screen Templates

    private func loadLockScreenTemplates() {
        guard fileManager.fileExists(atPath: lockScreenTemplatesFile.path) else {
            lockScreenTemplates = []
            return
        }

        do {
            let data = try Data(contentsOf: lockScreenTemplatesFile)
            lockScreenTemplates = try JSONDecoder().decode([LockScreenTemplate].self, from: data)
        } catch {
            print("Failed to load lock screen templates: \(error)")
            lockScreenTemplates = []
        }
    }

    private func saveLockScreenTemplates() {
        do {
            let data = try JSONEncoder().encode(lockScreenTemplates)
            try data.write(to: lockScreenTemplatesFile)
        } catch {
            print("Failed to save lock screen templates: \(error)")
        }
    }

    func addLockScreenTemplate(_ template: LockScreenTemplate) {
        lockScreenTemplates.append(template)
        saveLockScreenTemplates()
    }

    func updateLockScreenTemplate(_ template: LockScreenTemplate) {
        if let index = lockScreenTemplates.firstIndex(where: { $0.id == template.id }) {
            var updated = template
            updated.updatedAt = Date()
            lockScreenTemplates[index] = updated
            saveLockScreenTemplates()
        }
    }

    func deleteLockScreenTemplate(_ template: LockScreenTemplate) {
        lockScreenTemplates.removeAll { $0.id == template.id }
        saveLockScreenTemplates()
    }

    func deleteLockScreenTemplate(at offsets: IndexSet) {
        lockScreenTemplates.remove(atOffsets: offsets)
        saveLockScreenTemplates()
    }

    // MARK: - Photo Management

    func savePhoto(_ imageData: Data, for templateId: UUID) -> Data? {
        let photoFile = photosDirectory.appendingPathComponent("\(templateId.uuidString).jpg")
        do {
            try imageData.write(to: photoFile)
            return imageData
        } catch {
            print("Failed to save photo: \(error)")
            return nil
        }
    }

    func loadPhoto(for templateId: UUID) -> Data? {
        let photoFile = photosDirectory.appendingPathComponent("\(templateId.uuidString).jpg")
        return try? Data(contentsOf: photoFile)
    }

    func deletePhoto(for templateId: UUID) {
        let photoFile = photosDirectory.appendingPathComponent("\(templateId.uuidString).jpg")
        try? fileManager.removeItem(at: photoFile)
    }

    /// Compresses an image to JPEG with reasonable quality for storage
    func compressImage(_ imageData: Data, maxSizeKB: Int = 200) -> Data? {
        guard let uiImage = UIImage(data: imageData) else { return nil }

        var compression: CGFloat = 0.8
        var compressedData = uiImage.jpegData(compressionQuality: compression)

        while let data = compressedData, data.count > maxSizeKB * 1024, compression > 0.1 {
            compression -= 0.1
            compressedData = uiImage.jpegData(compressionQuality: compression)
        }

        return compressedData
    }
}
