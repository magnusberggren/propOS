//
//  ContactEditorSheet.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI
import PhotosUI

struct ContactEditorSheet: View {
    let contact: Contact?
    let phoneId: UUID
    let storage: CharacterPhoneStorageService

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var photoData: Data?
    @State private var iconName: String = "person.circle.fill"

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingIconPicker = false
    @State private var isLoadingPhoto = false

    private var isEditing: Bool { contact != nil }

    private let availableIcons = [
        "person.circle.fill",
        "person.fill",
        "heart.fill",
        "star.fill",
        "house.fill",
        "building.2.fill",
        "briefcase.fill",
        "phone.fill",
        "envelope.fill",
        "doc.fill",
        "folder.fill",
        "tray.fill",
        "archivebox.fill",
        "gear",
        "wrench.fill",
        "hammer.fill",
        "paintbrush.fill",
        "scissors",
        "pencil",
        "trash.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Avatar") {
                    HStack {
                        Spacer()
                        photoPreview
                        Spacer()
                    }

                    if isLoadingPhoto {
                        HStack {
                            Spacer()
                            ProgressView("Loading photo...")
                            Spacer()
                        }
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Choose Photo from Library", systemImage: "photo.on.rectangle")
                    }

                    Button {
                        showingIconPicker = true
                    } label: {
                        Label("Choose SF Symbol Icon", systemImage: "star.circle")
                    }

                    if photoData != nil {
                        Button(role: .destructive) {
                            photoData = nil
                        } label: {
                            Label("Remove Photo", systemImage: "trash")
                        }
                    }
                }

                Section("Contact Info") {
                    TextField("Name", text: $name)
                        .textContentType(.name)

                    TextField("Phone Number (optional)", text: $phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle(isEditing ? "Edit Contact" : "New Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveContact()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerSheet(selectedIcon: $iconName, icons: availableIcons)
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                guard let newValue else { return }
                isLoadingPhoto = true
                Task {
                    do {
                        // Try loading as UIImage first (more reliable)
                        if let image = try await newValue.loadTransferable(type: TransferableImage.self) {
                            await MainActor.run {
                                photoData = storage.compressImage(image.data)
                                isLoadingPhoto = false
                            }
                        } else {
                            await MainActor.run {
                                isLoadingPhoto = false
                            }
                        }
                    } catch {
                        print("Failed to load image: \(error)")
                        await MainActor.run {
                            isLoadingPhoto = false
                        }
                    }
                }
            }
            .onAppear {
                if let contact = contact {
                    name = contact.name
                    phoneNumber = contact.phoneNumber ?? ""
                    photoData = contact.photoData
                    iconName = contact.iconName
                }
            }
        }
    }

    private var photoPreview: some View {
        ZStack {
            if let photoData = photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 40))
                            .foregroundStyle(.gray)
                    )
            }
        }
    }

    private func saveContact() {
        if var existing = contact {
            existing.name = name
            existing.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
            existing.photoData = photoData
            existing.iconName = iconName
            storage.updateContact(existing, in: phoneId)
        } else {
            let newContact = Contact(
                name: name,
                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                photoData: photoData,
                iconName: iconName
            )
            storage.addContact(newContact, to: phoneId)
        }
    }
}

// Helper for reliable image loading from PhotosPicker
struct TransferableImage: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            TransferableImage(data: data)
        }
    }
}

struct IconPickerSheet: View {
    @Binding var selectedIcon: String
    let icons: [String]
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(selectedIcon == icon ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            selectedIcon == icon ? Color.blue : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        }
                        .foregroundStyle(selectedIcon == icon ? .blue : .primary)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContactEditorSheet(
        contact: nil,
        phoneId: UUID(),
        storage: CharacterPhoneStorageService.shared
    )
}
