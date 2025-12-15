//
//  PhoneSelectorView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

struct PhoneSelectorView: View {
    @Bindable var viewModel: ControllerViewModel
    @State private var showingPhoneEditor = false
    @State private var phoneToEdit: CharacterPhone?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Select Phone")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                Button {
                    phoneToEdit = nil
                    showingPhoneEditor = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, Spacing.md)

            if viewModel.phoneStorage.phones.isEmpty {
                emptyStateView
            } else {
                phoneScrollView
            }
        }
        .sheet(isPresented: $showingPhoneEditor) {
            PhoneEditorSheet(
                phone: phoneToEdit,
                storage: viewModel.phoneStorage
            )
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "iphone.gen3")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No Phones")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)

            Text("Create a character phone to get started")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingPhoneEditor = true
            } label: {
                Label("Create Phone", systemImage: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        .padding(.horizontal, Spacing.md)
    }

    private var phoneScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(viewModel.phoneStorage.phones) { phone in
                    PhoneCard(
                        phone: phone,
                        isSelected: viewModel.selectedPhone?.id == phone.id,
                        onSelect: {
                            viewModel.loadPhone(phone)
                        },
                        onEdit: {
                            phoneToEdit = phone
                            showingPhoneEditor = true
                        },
                        onDelete: {
                            viewModel.phoneStorage.deletePhone(phone)
                        }
                    )
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
        }
    }
}

struct PhoneCard: View {
    let phone: CharacterPhone
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onSelect) {
                VStack(spacing: Spacing.sm) {
                    // Phone preview
                    ZStack {
                        if let imageData = phone.wallpaperImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else if let wallpaper = Wallpaper(rawValue: phone.wallpaperName) {
                            wallpaper.background
                                .frame(width: 60, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(wallpaperGradient)
                                .frame(width: 60, height: 100)
                        }

                        // Phone frame
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.black.opacity(0.2), lineWidth: 2)
                            .frame(width: 60, height: 100)

                        // Contact count badge
                        if !phone.contacts.isEmpty {
                            Text("\(phone.contacts.count)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .clipShape(Capsule())
                                .offset(x: 20, y: -40)
                        }
                    }

                    // Phone name
                    Text(phone.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .frame(width: 80)
                }
            }
            .buttonStyle(.plain)

            // Edit/Delete buttons when selected
            if isSelected {
                HStack(spacing: 8) {
                    Button {
                        onEdit()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Edit")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 6)
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isSelected ? Color.blue : Color.black.opacity(0.06), lineWidth: isSelected ? 2 : 0.5)
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Delete \"\(phone.name)\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete this phone and all its contacts.")
        }
    }

    private var wallpaperGradient: LinearGradient {
        LinearGradient(
            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    ZStack {
        Color(uiColor: .systemGroupedBackground)
            .ignoresSafeArea()

        PhoneSelectorView(
            viewModel: ControllerViewModel(
                multipeerService: MultipeerService(mode: .controller)
            )
        )
    }
}
