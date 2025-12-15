//
//  ContactGridView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

struct ContactGridView: View {
    @Bindable var viewModel: ControllerViewModel
    @State private var showingContactEditor = false
    @State private var contactToEdit: Contact?

    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 100), spacing: Spacing.md)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Contacts")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                if viewModel.selectedPhone != nil {
                    Button {
                        contactToEdit = nil
                        showingContactEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)

            if let phone = viewModel.selectedPhone {
                if phone.contacts.isEmpty {
                    emptyContactsView
                } else {
                    contactsGrid(for: phone)
                }
            } else {
                noPhoneSelectedView
            }
        }
        .sheet(isPresented: $showingContactEditor) {
            if let phoneId = viewModel.selectedPhone?.id {
                ContactEditorSheet(
                    contact: contactToEdit,
                    phoneId: phoneId,
                    storage: viewModel.phoneStorage
                )
            }
        }
    }

    private var noPhoneSelectedView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "iphone.gen3.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No Phone Selected")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)

            Text("Select a phone above to see its contacts")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        .padding(.horizontal, Spacing.md)
    }

    private var emptyContactsView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No Contacts")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)

            Text("Add contacts to this phone")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingContactEditor = true
            } label: {
                Label("Add Contact", systemImage: "plus")
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

    private func contactsGrid(for phone: CharacterPhone) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Spacing.md) {
                ForEach(phone.contacts) { contact in
                    ContactCard(
                        contact: contact,
                        isSelected: viewModel.selectedContact?.id == contact.id,
                        onSelect: {
                            viewModel.selectedContact = contact
                        },
                        onEdit: {
                            contactToEdit = contact
                            showingContactEditor = true
                        },
                        onDelete: {
                            viewModel.phoneStorage.deleteContact(contact, from: phone.id)
                        }
                    )
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }
}

struct ContactCard: View {
    let contact: Contact
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: Spacing.sm) {
                // Contact avatar
                ZStack {
                    if let photoData = contact.photoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(avatarGradient)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: contact.iconName)
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            )
                    }

                    // Selection ring
                    if isSelected {
                        Circle()
                            .strokeBorder(Color.blue, lineWidth: 3)
                            .frame(width: 66, height: 66)
                    }
                }

                // Contact name
                Text(contact.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(width: 80)
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
            .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
        }
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
    }

    private var avatarGradient: LinearGradient {
        LinearGradient(
            colors: [.gray.opacity(0.6), .gray.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    ZStack {
        Color(uiColor: .systemGroupedBackground)
            .ignoresSafeArea()

        ContactGridView(
            viewModel: ControllerViewModel(
                multipeerService: MultipeerService(mode: .controller)
            )
        )
    }
}
