//
//  PhoneEditorSheet.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI
import PhotosUI

struct PhoneEditorSheet: View {
    let phone: CharacterPhone?
    let storage: CharacterPhoneStorageService

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var wallpaperName: String = Wallpaper.wallpaper1.rawValue
    @State private var wallpaperImageData: Data?
    @State private var carrierName: String = "Carrier"
    @State private var signalStrength: Int = 4
    @State private var batteryPercent: Int = 85

    @State private var selectedWallpaperItem: PhotosPickerItem?
    @State private var showingWallpaperPicker = false
    @State private var isLoadingWallpaper = false

    private var isEditing: Bool { phone != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Phone Info") {
                    TextField("Phone Name", text: $name)
                        .textContentType(.name)
                }

                Section("Wallpaper") {
                    wallpaperPreview

                    if isLoadingWallpaper {
                        HStack {
                            Spacer()
                            ProgressView("Loading wallpaper...")
                            Spacer()
                        }
                    }

                    Button {
                        showingWallpaperPicker = true
                    } label: {
                        Label("Choose Preset Wallpaper", systemImage: "paintpalette")
                    }

                    PhotosPicker(selection: $selectedWallpaperItem, matching: .images) {
                        Label("Choose Custom Photo", systemImage: "photo.on.rectangle")
                    }

                    if wallpaperImageData != nil {
                        Button(role: .destructive) {
                            wallpaperImageData = nil
                        } label: {
                            Label("Remove Custom Wallpaper", systemImage: "trash")
                        }
                    }
                }

                Section("Status Bar") {
                    TextField("Carrier Name", text: $carrierName)

                    Stepper("Signal: \(signalStrength) bars", value: $signalStrength, in: 0...4)

                    HStack {
                        Text("Battery")
                        Slider(value: Binding(
                            get: { Double(batteryPercent) },
                            set: { batteryPercent = Int($0) }
                        ), in: 0...100, step: 5)
                        Text("\(batteryPercent)%")
                            .frame(width: 45, alignment: .trailing)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Phone" : "New Phone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePhone()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingWallpaperPicker) {
                WallpaperPickerSheet(selectedWallpaper: $wallpaperName)
            }
            .onChange(of: selectedWallpaperItem) { _, newValue in
                guard let newValue else { return }
                isLoadingWallpaper = true
                Task {
                    do {
                        if let image = try await newValue.loadTransferable(type: TransferableImage.self) {
                            await MainActor.run {
                                wallpaperImageData = storage.compressImage(image.data)
                                isLoadingWallpaper = false
                            }
                        } else {
                            await MainActor.run {
                                isLoadingWallpaper = false
                            }
                        }
                    } catch {
                        print("Failed to load wallpaper: \(error)")
                        await MainActor.run {
                            isLoadingWallpaper = false
                        }
                    }
                }
            }
            .onAppear {
                if let phone = phone {
                    name = phone.name
                    wallpaperName = phone.wallpaperName
                    wallpaperImageData = phone.wallpaperImageData
                    carrierName = phone.carrierName
                    signalStrength = phone.signalStrength
                    batteryPercent = phone.batteryPercent
                }
            }
        }
    }

    private var wallpaperPreview: some View {
        ZStack {
            if let imageData = wallpaperImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let wallpaper = Wallpaper(rawValue: wallpaperName) {
                wallpaper.background
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.3))
                    .frame(height: 150)
            }

            // Status bar preview
            VStack {
                HStack {
                    Text(carrierName)
                        .font(.caption2)
                    Spacer()
                    HStack(spacing: 2) {
                        ForEach(0..<4, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(i < signalStrength ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 4, height: 6 + CGFloat(i) * 2)
                        }
                    }
                    Text("\(batteryPercent)%")
                        .font(.caption2)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.top, 4)

                Spacer()
            }
        }
    }

    private func savePhone() {
        if var existing = phone {
            existing.name = name
            existing.wallpaperName = wallpaperName
            existing.wallpaperImageData = wallpaperImageData
            existing.carrierName = carrierName
            existing.signalStrength = signalStrength
            existing.batteryPercent = batteryPercent
            storage.updatePhone(existing)
        } else {
            let newPhone = CharacterPhone(
                name: name,
                wallpaperName: wallpaperName,
                wallpaperImageData: wallpaperImageData,
                carrierName: carrierName,
                signalStrength: signalStrength,
                batteryPercent: batteryPercent
            )
            storage.addPhone(newPhone)
        }
    }
}

struct WallpaperPickerSheet: View {
    @Binding var selectedWallpaper: String
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Wallpaper.allCases) { wallpaper in
                        Button {
                            selectedWallpaper = wallpaper.rawValue
                            dismiss()
                        } label: {
                            wallpaper.background
                                .aspectRatio(9/16, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(
                                            selectedWallpaper == wallpaper.rawValue ? Color.blue : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Wallpaper")
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
    PhoneEditorSheet(
        phone: nil,
        storage: CharacterPhoneStorageService.shared
    )
}
