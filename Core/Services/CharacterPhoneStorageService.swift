//
//  CharacterPhoneStorageService.swift
//  PropPhone
//
//  Created by Claude Code
//

import Foundation
import SwiftUI

@Observable
final class CharacterPhoneStorageService {
    static let shared = CharacterPhoneStorageService()

    private(set) var phones: [CharacterPhone] = []

    private let fileManager = FileManager.default

    private var phonesDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("phones", isDirectory: true)
    }

    private var phonesFile: URL {
        phonesDirectory.appendingPathComponent("character_phones.json")
    }

    init() {
        createDirectoriesIfNeeded()
        loadPhones()
        migrateIfNeeded()
    }

    // MARK: - Directory Management

    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: phonesDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Phone CRUD

    private func loadPhones() {
        guard fileManager.fileExists(atPath: phonesFile.path) else {
            phones = []
            return
        }

        do {
            let data = try Data(contentsOf: phonesFile)
            phones = try JSONDecoder().decode([CharacterPhone].self, from: data)
        } catch {
            print("Failed to load phones: \(error)")
            phones = []
        }
    }

    private func savePhones() {
        do {
            let data = try JSONEncoder().encode(phones)
            try data.write(to: phonesFile)
        } catch {
            print("Failed to save phones: \(error)")
        }
    }

    func addPhone(_ phone: CharacterPhone) {
        phones.append(phone)
        savePhones()
    }

    func updatePhone(_ phone: CharacterPhone) {
        if let index = phones.firstIndex(where: { $0.id == phone.id }) {
            var updated = phone
            updated.updatedAt = Date()
            phones[index] = updated
            savePhones()
        }
    }

    func deletePhone(_ phone: CharacterPhone) {
        phones.removeAll { $0.id == phone.id }
        savePhones()
    }

    func deletePhone(at offsets: IndexSet) {
        phones.remove(atOffsets: offsets)
        savePhones()
    }

    // MARK: - Contact CRUD

    func addContact(_ contact: Contact, to phoneId: UUID) {
        guard let index = phones.firstIndex(where: { $0.id == phoneId }) else { return }
        phones[index].contacts.append(contact)
        phones[index].updatedAt = Date()
        savePhones()
    }

    func updateContact(_ contact: Contact, in phoneId: UUID) {
        guard let phoneIndex = phones.firstIndex(where: { $0.id == phoneId }),
              let contactIndex = phones[phoneIndex].contacts.firstIndex(where: { $0.id == contact.id }) else { return }

        var updated = contact
        updated.updatedAt = Date()
        phones[phoneIndex].contacts[contactIndex] = updated
        phones[phoneIndex].updatedAt = Date()
        savePhones()
    }

    func deleteContact(_ contact: Contact, from phoneId: UUID) {
        guard let phoneIndex = phones.firstIndex(where: { $0.id == phoneId }) else { return }
        phones[phoneIndex].contacts.removeAll { $0.id == contact.id }
        phones[phoneIndex].updatedAt = Date()
        savePhones()
    }

    // MARK: - Image Compression

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

    // MARK: - Migration

    private var hasMigrated: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedCharacterPhoneMigration") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedCharacterPhoneMigration") }
    }

    private func migrateIfNeeded() {
        guard !hasMigrated else { return }

        let templateService = TemplateStorageService.shared

        // Migrate CallTemplates to contacts in a "Migrated Contacts" phone
        if !templateService.callTemplates.isEmpty {
            var migratedPhone = CharacterPhone(name: "Migrated Contacts")
            for callTemplate in templateService.callTemplates {
                let contact = Contact(
                    name: callTemplate.callerName,
                    phoneNumber: callTemplate.callerNumber,
                    photoData: callTemplate.callerPhotoData,
                    iconName: callTemplate.callerIcon
                )
                migratedPhone.contacts.append(contact)
            }
            phones.append(migratedPhone)
        }

        // Migrate LockScreenTemplates to CharacterPhones (just settings, no contacts)
        for lockTemplate in templateService.lockScreenTemplates {
            let phone = CharacterPhone(
                name: lockTemplate.name,
                wallpaperName: lockTemplate.wallpaperName,
                wallpaperImageData: lockTemplate.wallpaperImageData
            )
            phones.append(phone)
        }

        if !phones.isEmpty {
            savePhones()
        }

        hasMigrated = true
    }

    /// Force re-migration (for debugging)
    func resetMigration() {
        hasMigrated = false
        phones = []
        savePhones()
        migrateIfNeeded()
    }
}
