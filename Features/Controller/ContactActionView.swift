//
//  ContactActionView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

struct ContactActionView: View {
    @Bindable var viewModel: ControllerViewModel
    @FocusState private var isMessageFocused: Bool
    @State private var showingContactEditor = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            if let contact = viewModel.selectedContact {
                // Selected contact header
                contactHeader(contact)

                // Action buttons
                HStack(spacing: Spacing.lg) {
                    // Voice call
                    ActionButton(
                        title: "Call",
                        icon: "phone.fill",
                        color: .green
                    ) {
                        viewModel.callContact(contact, isVideo: false)
                    }

                    // Video call
                    ActionButton(
                        title: "Video",
                        icon: "video.fill",
                        color: .blue
                    ) {
                        viewModel.callContact(contact, isVideo: true)
                    }

                    // Dismiss call
                    ActionButton(
                        title: "End",
                        icon: "phone.down.fill",
                        color: .red
                    ) {
                        viewModel.dismissCall()
                    }
                }
                .padding(.horizontal, Spacing.md)

                // Message input
                messageInput(contact)
            } else {
                noContactSelectedView
            }
        }
        .padding(.vertical, Spacing.md)
        .sheet(isPresented: $showingContactEditor) {
            if let contact = viewModel.selectedContact,
               let phoneId = viewModel.selectedPhone?.id {
                ContactEditorSheet(
                    contact: contact,
                    phoneId: phoneId,
                    storage: viewModel.phoneStorage
                )
            }
        }
        .alert("Delete Contact", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let contact = viewModel.selectedContact,
                   let phoneId = viewModel.selectedPhone?.id {
                    viewModel.phoneStorage.deleteContact(contact, from: phoneId)
                    viewModel.selectedContact = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this contact?")
        }
    }

    private func contactHeader(_ contact: Contact) -> some View {
        HStack(spacing: Spacing.md) {
            // Contact avatar
            if let photoData = contact.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(.gray.opacity(0.5))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: contact.iconName)
                            .font(.title2)
                            .foregroundStyle(.white)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)

                if let number = contact.phoneNumber {
                    Text(number)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Edit button
            Button {
                showingContactEditor = true
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }

            // Delete button
            Button {
                showingDeleteConfirmation = true
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
            }

            // Deselect button
            Button {
                viewModel.selectedContact = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private func messageInput(_ contact: Contact) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                TextField("Message text...", text: $viewModel.draftMessageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1...4)
                    .focused($isMessageFocused)

                Button {
                    viewModel.sendDraftMessage()
                    isMessageFocused = false
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.draftMessageText.isEmpty ? .gray : Color.blue)
                }
                .disabled(viewModel.draftMessageText.isEmpty)
            }

            HStack {
                Toggle(isOn: $viewModel.draftMessageIsUrgent) {
                    Label("Urgent", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(viewModel.draftMessageIsUrgent ? .orange : .secondary)
                }
                .toggleStyle(.button)
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        .padding(.horizontal, Spacing.md)
    }

    private var noContactSelectedView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No Contact Selected")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)

            Text("Select a contact to trigger calls or messages")
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
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .clipShape(Circle())

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
            }
        }
    }
}

#Preview {
    ZStack {
        Color(uiColor: .systemGroupedBackground)
            .ignoresSafeArea()

        ContactActionView(
            viewModel: ControllerViewModel(
                multipeerService: MultipeerService(mode: .controller)
            )
        )
    }
}
