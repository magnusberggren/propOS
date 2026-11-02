//
//  VoicemailTab.swift
//  PropPhone
//
//  The scene-critical screen: a faithful classic Voicemail tab.
//  Unheard dots, inline expansion with a working scrubber, real
//  audio playback, speaker toggle, call back, delete. All state
//  changes flow through PhoneRuntime, so RESET restores everything
//  between takes.
//

import SwiftUI

struct VoicemailTab: View {
    let runtime: PhoneRuntime
    let appState: PhoneAppState

    var body: some View {
        VStack(spacing: 0) {
            LargeTitleHeader(title: "Voicemail") {
                Text("Greeting")
            } trailing: {
                Text("Edit")
            }

            if runtime.state.profile.voicemails.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "recordingtape")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(uiColor: .systemGray2))
                    Text("No Voicemail")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color(uiColor: .systemGray))
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(runtime.state.profile.voicemails) { message in
                            VoicemailRow(
                                runtime: runtime,
                                message: message,
                                isExpanded: appState.expandedVoicemailID == message.id,
                                isHeard: runtime.state.heardVoicemailIDs.contains(message.id)
                            )
                            Divider()
                                .padding(.leading, 34)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Row

struct VoicemailRow: View {
    let runtime: PhoneRuntime
    let message: VoicemailMessage
    let isExpanded: Bool
    let isHeard: Bool

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    runtime.tapVoicemail(message)
                }
            } label: {
                HStack(spacing: 0) {
                    Circle()
                        .fill(Color.accentBlue)
                        .frame(width: 9, height: 9)
                        .opacity(isHeard ? 0 : 1)
                        .padding(.horizontal, 6)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(message.resolvedName(in: runtime.state.profile))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(message.subtitle)
                            .font(.system(size: 15))
                            .foregroundStyle(Color(uiColor: .systemGray))
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(message.dateLabel)
                            .font(.system(size: 15))
                        Text(PropFormat.duration(displayDuration))
                            .font(.system(size: 15))
                    }
                    .foregroundStyle(Color(uiColor: .systemGray))

                    Image(systemName: "info.circle")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.accentBlue)
                        .padding(.leading, 10)
                        .padding(.trailing, 16)
                }
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VoicemailPlayerPane(runtime: runtime, message: message)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                    .transition(.opacity)
            }
        }
        .background(isExpanded ? Color(uiColor: .systemGray6) : Color.clear)
    }

    private var displayDuration: TimeInterval {
        let audio = runtime.audio
        if audio.loadedMessageID == message.id, audio.duration > 0 {
            return audio.duration
        }
        return message.duration
    }
}

// MARK: - Player pane

struct VoicemailPlayerPane: View {
    let runtime: PhoneRuntime
    let message: VoicemailMessage

    var body: some View {
        let audio = runtime.audio
        let isCurrent = audio.loadedMessageID == message.id

        VStack(spacing: 10) {
            // Scrubber
            VStack(spacing: 3) {
                ScrubberBar(
                    progress: isCurrent ? audio.progress : 0,
                    duration: isCurrent ? max(audio.duration, 0.1) : max(message.duration, 0.1)
                ) { time in
                    audio.seek(to: time)
                }

                HStack {
                    Text(PropFormat.duration(isCurrent ? audio.progress : 0))
                    Spacer()
                    Text("-" + PropFormat.duration(
                        (isCurrent ? audio.duration : message.duration) - (isCurrent ? audio.progress : 0)
                    ))
                }
                .font(.system(size: 13))
                .monospacedDigit()
                .foregroundStyle(Color(uiColor: .systemGray))
            }

            if let transcription = message.transcription, !transcription.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Transcription")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(uiColor: .systemGray))
                    Text("“\(transcription)”")
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
            }

            HStack {
                Button {
                    audio.togglePlay()
                } label: {
                    Image(systemName: (isCurrent && audio.isPlaying) ? "pause.fill" : "play.fill")
                        .font(.system(size: 21))
                        .foregroundStyle(.primary)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(Color(uiColor: .systemGray5)))
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    audio.toggleSpeaker()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 15))
                        Text("Speaker")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(audio.isSpeaker ? .white : Color.accentBlue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        Capsule().fill(audio.isSpeaker ? Color.accentBlue : Color(uiColor: .systemGray5))
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    runtime.callBack(from: message)
                } label: {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 19))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(Color(red: 0.20, green: 0.78, blue: 0.29)))
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        runtime.deleteVoicemail(message)
                    }
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 19))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(Color(red: 1.0, green: 0.23, blue: 0.19)))
                }
                .buttonStyle(.plain)
                .padding(.leading, 10)
            }
        }
        .padding(.top, 2)
    }
}

// MARK: - Scrubber

struct ScrubberBar: View {
    var progress: TimeInterval
    var duration: TimeInterval
    var onSeek: (TimeInterval) -> Void

    @State private var dragging = false

    var body: some View {
        GeometryReader { geo in
            let fraction = max(0, min(1, progress / duration))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(uiColor: .systemGray4))
                    .frame(height: 3)

                Capsule()
                    .fill(Color(uiColor: .systemGray))
                    .frame(width: geo.size.width * fraction, height: 3)

                Circle()
                    .fill(.white)
                    .frame(width: dragging ? 22 : 14, height: dragging ? 22 : 14)
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
                    .offset(x: geo.size.width * fraction - (dragging ? 11 : 7))
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragging = true
                        let f = max(0, min(1, value.location.x / geo.size.width))
                        onSeek(f * duration)
                    }
                    .onEnded { _ in dragging = false }
            )
        }
        .frame(height: 24)
    }
}
