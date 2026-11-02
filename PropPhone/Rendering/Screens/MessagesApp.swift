//
//  MessagesApp.swift
//  PropPhone
//
//  The Messages replica: conversation list and thread view with
//  iMessage-style bubbles, date separators, Delivered, an animated
//  typing indicator, and a working input bar — the actor types on
//  the real system keyboard and sends, and the controller can drop
//  incoming texts in live.
//

import SwiftUI

struct MessagesAppScreen: View {
    let runtime: PhoneRuntime
    let appState: MessagesAppState
    let displayTime: Date

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                IOSStatusBar(
                    style: .inApp,
                    spec: runtime.state.profile.statusBar,
                    time: displayTime,
                    tint: .primary
                )
                .padding(.horizontal, 20)
                .padding(.top, DeviceMetrics.top - 47)

                if let threadID = appState.openThreadID,
                   let thread = runtime.state.profile.thread(threadID) {
                    ThreadView(runtime: runtime, thread: thread)
                } else {
                    ConversationListView(runtime: runtime)
                }
            }
        }
        .environment(\.colorScheme, .light)
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.startLocation.y > UIScreen.main.bounds.height - 44,
                       value.translation.height < -50 {
                        runtime.goHome()
                    }
                }
        )
    }
}

// MARK: - Conversation list

struct ConversationListView: View {
    let runtime: PhoneRuntime

    var body: some View {
        VStack(spacing: 0) {
            LargeTitleHeader(title: "Messages") {
                Text("Edit")
            } trailing: {
                Image(systemName: "square.and.pencil")
            }

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                Text("Search")
                    .font(.system(size: 17))
                Spacer()
            }
            .foregroundStyle(Color(uiColor: .systemGray))
            .padding(.horizontal, 8)
            .frame(height: 36)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(uiColor: .systemGray6)))
            .padding(.horizontal, 16)
            .padding(.bottom, 6)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(runtime.state.profile.threads) { thread in
                        ConversationRow(runtime: runtime, thread: thread)
                        Divider().padding(.leading, 80)
                    }
                }
            }
        }
    }
}

struct ConversationRow: View {
    let runtime: PhoneRuntime
    let thread: MessageThread

    var body: some View {
        Button {
            runtime.openThread(thread.id)
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.accentBlue)
                    .frame(width: 10, height: 10)
                    .opacity(thread.isUnread ? 1 : 0)
                    .padding(.leading, 2)

                AvatarView(
                    name: thread.resolvedName(in: runtime.state.profile),
                    monogram: monogram,
                    imageAsset: runtime.state.profile.contact(thread.contactID)?.imageAsset,
                    size: 45,
                    assetGeneration: runtime.assetGeneration
                )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(thread.resolvedName(in: runtime.state.profile))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Spacer()

                        Text(timeLabel)
                            .font(.system(size: 15))
                            .foregroundStyle(Color(uiColor: .systemGray))

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(uiColor: .systemGray3))
                    }

                    Text(thread.previewText)
                        .font(.system(size: 15))
                        .foregroundStyle(Color(uiColor: .systemGray))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var monogram: String {
        runtime.state.profile.contact(thread.contactID)?.monogram
            ?? String(thread.resolvedName(in: runtime.state.profile).prefix(1))
    }

    private var timeLabel: String {
        // Newest message's separator hint, falling back to the display clock style.
        thread.messages.last(where: { $0.separatorLabel != nil })?.separatorLabel?
            .components(separatedBy: " ").first ?? "09:41"
    }
}

// MARK: - Thread view

struct ThreadView: View {
    let runtime: PhoneRuntime
    let thread: MessageThread

    @State private var draft = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            threadHeader

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(groupedMessages, id: \.message.id) { item in
                            if let separator = item.message.separatorLabel {
                                Text(attributedSeparator(separator))
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(uiColor: .systemGray))
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                            }

                            MessageBubble(
                                text: item.message.text,
                                isOutgoing: item.message.isOutgoing,
                                showTail: item.isLastInGroup
                            )
                            .padding(.top, item.startsGroup ? 6 : 0)
                            .id(item.message.id)
                        }

                        if let last = thread.messages.last, last.isOutgoing {
                            HStack {
                                Spacer()
                                Text("Delivered")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(uiColor: .systemGray))
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 2)
                        }

                        if thread.isTyping {
                            TypingIndicatorBubble()
                                .padding(.top, 6)
                                .id("typing")
                        }

                        Color.clear.frame(height: 8).id("bottom")
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
                .onAppear {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
                .onChange(of: thread.messages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: thread.isTyping) { _, typing in
                    if typing {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }

            inputBar
        }
    }

    private var threadHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Button {
                    runtime.closeThread()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 23, weight: .medium))
                        .foregroundStyle(Color.accentBlue)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(spacing: 2) {
                    AvatarView(
                        name: thread.resolvedName(in: runtime.state.profile),
                        monogram: runtime.state.profile.contact(thread.contactID)?.monogram
                            ?? String(thread.resolvedName(in: runtime.state.profile).prefix(1)),
                        imageAsset: runtime.state.profile.contact(thread.contactID)?.imageAsset,
                        size: 40,
                        assetGeneration: runtime.assetGeneration
                    )
                    HStack(spacing: 2) {
                        Text(thread.resolvedName(in: runtime.state.profile))
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color(uiColor: .systemGray2))
                    }
                }

                Spacer()

                Button {} label: {
                    Image(systemName: "video")
                        .font(.system(size: 21))
                        .foregroundStyle(Color.accentBlue)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)

            Divider()
        }
        .background(.bar)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            Button {} label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color(uiColor: .systemGray))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color(uiColor: .systemGray5)))
            }
            .buttonStyle(.plain)

            HStack(spacing: 4) {
                TextField("iMessage", text: $draft, axis: .vertical)
                    .font(.system(size: 17))
                    .lineLimit(1...5)
                    .focused($inputFocused)

                if draft.isEmpty {
                    Image(systemName: "mic")
                        .font(.system(size: 17))
                        .foregroundStyle(Color(uiColor: .systemGray))
                } else {
                    Button {
                        runtime.sendTypedMessage(draft)
                        draft = ""
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Color.accentBlue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 5)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color(uiColor: .systemGray4), lineWidth: 1)
            )
        }
        .padding(.horizontal, 12)
        .padding(.top, 7)
        .padding(.bottom, inputFocused ? 10 : DeviceMetrics.bottom + 2)
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: Grouping

    private struct GroupedMessage {
        let message: ChatMessage
        let startsGroup: Bool
        let isLastInGroup: Bool
    }

    private var groupedMessages: [GroupedMessage] {
        let messages = thread.messages
        return messages.enumerated().map { i, m in
            let prev = i > 0 ? messages[i - 1] : nil
            let next = i < messages.count - 1 ? messages[i + 1] : nil
            return GroupedMessage(
                message: m,
                startsGroup: prev?.isOutgoing != m.isOutgoing || m.separatorLabel != nil,
                isLastInGroup: next?.isOutgoing != m.isOutgoing || next?.separatorLabel != nil
            )
        }
    }

    /// "Today 09:12" renders the leading word bold, like iOS.
    private func attributedSeparator(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        if let space = text.firstIndex(of: " ") {
            let head = String(text[..<space])
            if let range = attributed.range(of: head) {
                attributed[range].font = .system(size: 12, weight: .semibold)
            }
        }
        return attributed
    }
}

// MARK: - Bubbles

struct MessageBubble: View {
    let text: String
    let isOutgoing: Bool
    var showTail = true

    static let outgoingBlue = Color(red: 0.04, green: 0.52, blue: 1.0)

    var body: some View {
        HStack {
            if isOutgoing { Spacer(minLength: 60) }

            Text(text)
                .font(.system(size: 17))
                .foregroundStyle(isOutgoing ? .white : .primary)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(
                    BubbleShape(isOutgoing: isOutgoing, showTail: showTail)
                        .fill(isOutgoing ? MessageBubble.outgoingBlue : Color(uiColor: .systemGray5))
                )

            if !isOutgoing { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 4)
    }
}

/// Rounded bubble with the iMessage corner tail.
struct BubbleShape: Shape {
    let isOutgoing: Bool
    var showTail = true

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        var path = Path(roundedRect: rect, cornerRadius: radius, style: .continuous)

        guard showTail else { return path }

        var tail = Path()
        if isOutgoing {
            let x = rect.maxX
            tail.move(to: CGPoint(x: x - radius, y: rect.maxY))
            tail.addQuadCurve(
                to: CGPoint(x: x + 4.5, y: rect.maxY),
                control: CGPoint(x: x, y: rect.maxY)
            )
            tail.addQuadCurve(
                to: CGPoint(x: x - 2, y: rect.maxY - 7),
                control: CGPoint(x: x + 0.5, y: rect.maxY - 2)
            )
        } else {
            let x = rect.minX
            tail.move(to: CGPoint(x: x + radius, y: rect.maxY))
            tail.addQuadCurve(
                to: CGPoint(x: x - 4.5, y: rect.maxY),
                control: CGPoint(x: x, y: rect.maxY)
            )
            tail.addQuadCurve(
                to: CGPoint(x: x + 2, y: rect.maxY - 7),
                control: CGPoint(x: x - 0.5, y: rect.maxY - 2)
            )
        }
        tail.closeSubpath()
        path.addPath(tail)
        return path
    }
}

// MARK: - Typing indicator

struct TypingIndicatorBubble: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.35)) { context in
            let phase = Int(context.date.timeIntervalSinceReferenceDate / 0.35) % 3

            HStack {
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color(uiColor: .systemGray2))
                            .frame(width: 9, height: 9)
                            .opacity(phase == i ? 1 : 0.4)
                            .scaleEffect(phase == i ? 1.15 : 1)
                            .animation(.easeInOut(duration: 0.3), value: phase)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(
                    BubbleShape(isOutgoing: false, showTail: true)
                        .fill(Color(uiColor: .systemGray5))
                )
                .padding(.horizontal, 4)

                Spacer(minLength: 60)
            }
        }
    }
}
