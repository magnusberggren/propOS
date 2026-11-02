//
//  ThreadComposer.swift
//  PropPhone
//
//  Authoring message threads: conversation history, unread state,
//  and per-message date separators. Everything the Messages replica
//  renders is written here.
//

import SwiftUI

struct ThreadComposer: View {
    @Binding var phone: PhoneProfile

    var body: some View {
        List {
            Section {
                ForEach($phone.threads) { $thread in
                    NavigationLink {
                        ThreadEditor(phone: $phone, thread: $thread)
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                                .opacity(thread.isUnread ? 1 : 0)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(thread.resolvedName(in: phone))
                                    .font(.subheadline.weight(.medium))
                                Text("\(thread.messages.count) messages")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onMove { from, to in
                    phone.threads.move(fromOffsets: from, toOffset: to)
                }
                .onDelete { indexSet in
                    phone.threads.remove(atOffsets: indexSet)
                }
            } footer: {
                Text("Top of the list is the newest conversation.")
            }

            Section("Add thread") {
                ForEach(phone.contacts.filter { contact in
                    !phone.threads.contains { $0.contactID == contact.id }
                }) { contact in
                    Button {
                        phone.threads.insert(MessageThread(contactID: contact.id), at: 0)
                    } label: {
                        Label(contact.displayName, systemImage: "plus")
                    }
                }

                Button {
                    phone.threads.insert(MessageThread(displayName: "Unknown"), at: 0)
                } label: {
                    Label("Unknown number", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Threads")
        .toolbar { EditButton() }
    }
}

// MARK: - Single thread editor

struct ThreadEditor: View {
    @Binding var phone: PhoneProfile
    @Binding var thread: MessageThread

    @State private var newText = ""
    @State private var newIsOutgoing = false
    @State private var newSeparator = ""

    var body: some View {
        List {
            Section {
                Picker("Contact", selection: $thread.contactID) {
                    Text("Custom / Unknown").tag(UUID?.none)
                    ForEach(phone.contacts) { contact in
                        Text(contact.displayName).tag(Optional(contact.id))
                    }
                }
                if thread.contactID == nil {
                    TextField("Display name", text: $thread.displayName)
                }
                Toggle("Unread at scene start", isOn: $thread.isUnread)
            }

            Section("Conversation") {
                ForEach($thread.messages) { $message in
                    VStack(alignment: .leading, spacing: 4) {
                        if let separator = message.separatorLabel {
                            Text(separator)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                        HStack {
                            if message.isOutgoing { Spacer(minLength: 40) }
                            Text(message.text)
                                .font(.subheadline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(message.isOutgoing ? Color.blue.opacity(0.85) : Color(uiColor: .systemGray5))
                                )
                                .foregroundStyle(message.isOutgoing ? .white : .primary)
                            if !message.isOutgoing { Spacer(minLength: 40) }
                        }
                    }
                }
                .onMove { from, to in
                    thread.messages.move(fromOffsets: from, toOffset: to)
                }
                .onDelete { indexSet in
                    thread.messages.remove(atOffsets: indexSet)
                }
            }

            Section("Add message") {
                TextField("Text", text: $newText, axis: .vertical)
                    .lineLimit(1...4)
                Picker("Direction", selection: $newIsOutgoing) {
                    Text("Received").tag(false)
                    Text("Sent by character").tag(true)
                }
                .pickerStyle(.segmented)
                TextField("Date separator above (optional, e.g. Today 09:12)", text: $newSeparator)
                    .font(.footnote)
                Button {
                    thread.messages.append(ChatMessage(
                        text: newText,
                        isOutgoing: newIsOutgoing,
                        separatorLabel: newSeparator.isEmpty ? nil : newSeparator
                    ))
                    newText = ""
                    newSeparator = ""
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .disabled(newText.isEmpty)
            }
        }
        .navigationTitle(thread.resolvedName(in: phone))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
    }
}
