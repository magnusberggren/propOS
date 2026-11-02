//
//  VoicemailComposer.swift
//  PropPhone
//
//  Authoring the voicemail box: order, caller, timestamps, heard
//  state, transcription, and audio — recorded in-app, imported from
//  Files, or generated as TTS scratch for rehearsal.
//

import AVFoundation
import Observation
import SwiftUI
import UniformTypeIdentifiers

struct VoicemailComposer: View {
    @Binding var phone: PhoneProfile

    var body: some View {
        List {
            Section {
                ForEach($phone.voicemails) { $message in
                    NavigationLink {
                        VoicemailEditor(phone: $phone, message: $message)
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                                .opacity(message.startsHeard ? 0 : 1)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(message.resolvedName(in: phone))
                                    .font(.subheadline.weight(.medium))
                                Text(message.dateLabel + " · " + PropFormat.duration(message.duration))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: message.audioAsset == nil ? "waveform.slash" : "waveform")
                                .font(.footnote)
                                .foregroundStyle(message.audioAsset == nil ? .orange : .green)
                        }
                    }
                }
                .onMove { from, to in
                    phone.voicemails.move(fromOffsets: from, toOffset: to)
                }
                .onDelete { indexSet in
                    phone.voicemails.remove(atOffsets: indexSet)
                }
            } footer: {
                Text("Top of the list is the newest message on the phone. Rows without audio play as timed silence for rehearsal.")
            }

            Button {
                phone.voicemails.insert(VoicemailMessage(displayName: "Unknown"), at: 0)
            } label: {
                Label("Add voicemail", systemImage: "plus")
            }
        }
        .navigationTitle("Voicemails")
        .toolbar { EditButton() }
    }
}

// MARK: - Single message editor

struct VoicemailEditor: View {
    @Binding var phone: PhoneProfile
    @Binding var message: VoicemailMessage

    @State private var recorder = VoicemailRecorder()
    @State private var showImporter = false
    @State private var previewPlayer: AVAudioPlayer?
    @State private var ttsBusy = false
    @State private var errorText: String?

    var body: some View {
        Form {
            Section("Caller") {
                Picker("Contact", selection: $message.contactID) {
                    Text("Custom / Unknown").tag(UUID?.none)
                    ForEach(phone.contacts) { contact in
                        Text(contact.displayName).tag(Optional(contact.id))
                    }
                }
                if message.contactID == nil {
                    TextField("Display name (e.g. Unknown)", text: $message.displayName)
                }
                TextField("Subtitle (mobile, Oslo…)", text: $message.subtitle)
            }

            Section("Listing") {
                TextField("Date label (Yesterday, 09:12…)", text: $message.dateLabel)
                Toggle("Already listened at scene start", isOn: $message.startsHeard)
                if message.audioAsset == nil {
                    Stepper(
                        "Length: \(PropFormat.duration(message.duration))",
                        value: $message.duration, in: 1...600, step: 1
                    )
                }
            }

            Section("Transcription") {
                TextEditor(text: Binding(
                    get: { message.transcription ?? "" },
                    set: { message.transcription = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 90)
            }

            audioSection

            if let errorText {
                Section {
                    Text(errorText).foregroundStyle(.red).font(.footnote)
                }
            }
        }
        .navigationTitle("Voicemail")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.audio]) { result in
            if case .success(let url) = result {
                let secured = url.startAccessingSecurityScopedResource()
                defer { if secured { url.stopAccessingSecurityScopedResource() } }
                do {
                    attachAudio(try AssetStore.shared.importFile(at: url))
                } catch {
                    errorText = "Import failed: \(error.localizedDescription)"
                }
            }
        }
        .onDisappear {
            recorder.cancel()
            previewPlayer?.stop()
        }
    }

    private var audioSection: some View {
        Section("Audio") {
            if message.audioAsset != nil {
                HStack {
                    Label("Audio attached", systemImage: "waveform")
                        .foregroundStyle(.green)
                    Spacer()
                    Text(PropFormat.duration(message.duration))
                        .foregroundStyle(.secondary)
                }

                Button {
                    playPreview()
                } label: {
                    Label("Play", systemImage: "play.fill")
                }

                Button(role: .destructive) {
                    message.audioAsset = nil
                } label: {
                    Label("Remove audio", systemImage: "trash")
                }
            }

            if recorder.isRecording {
                Button {
                    if let url = recorder.stop() {
                        do {
                            attachAudio(try AssetStore.shared.importFile(at: url))
                        } catch {
                            errorText = "Recording failed: \(error.localizedDescription)"
                        }
                    }
                } label: {
                    Label(
                        "Stop recording · \(PropFormat.duration(recorder.elapsed))",
                        systemImage: "stop.circle.fill"
                    )
                    .foregroundStyle(.red)
                }
            } else {
                Button {
                    recorder.start { granted in
                        if !granted { errorText = "Microphone access is required to record." }
                    }
                } label: {
                    Label("Record message", systemImage: "mic.fill")
                }
            }

            Button {
                showImporter = true
            } label: {
                Label("Import audio file", systemImage: "square.and.arrow.down")
            }

            Button {
                generateTTS()
            } label: {
                if ttsBusy {
                    Label("Generating…", systemImage: "waveform.badge.magnifyingglass")
                } else {
                    Label("Generate scratch audio from transcription", systemImage: "text.bubble")
                }
            }
            .disabled((message.transcription ?? "").isEmpty || ttsBusy)
        }
    }

    private func attachAudio(_ ref: AssetRef) {
        message.audioAsset = ref
        if let player = try? AVAudioPlayer(contentsOf: AssetStore.shared.url(for: ref)) {
            message.duration = player.duration
        }
        errorText = nil
    }

    private func playPreview() {
        guard let ref = message.audioAsset else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        previewPlayer = try? AVAudioPlayer(contentsOf: AssetStore.shared.url(for: ref))
        previewPlayer?.play()
    }

    private func generateTTS() {
        guard let text = message.transcription else { return }
        ttsBusy = true
        SpeechRenderer.renderScratchAudio(text: text) { result in
            ttsBusy = false
            switch result {
            case .success(let ref): attachAudio(ref)
            case .failure(let error): errorText = "TTS failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Recorder

@Observable
final class VoicemailRecorder {
    private(set) var isRecording = false
    private(set) var elapsed: TimeInterval = 0

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var fileURL: URL?

    func start(permission: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                permission(granted)
                guard granted, let self else { return }
                self.beginRecording()
            }
        }
    }

    private func beginRecording() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
            try session.setActive(true)
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.record()
            self.recorder = recorder
            self.fileURL = url
            self.elapsed = 0
            self.isRecording = true
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.elapsed = self?.recorder?.currentTime ?? 0
            }
        } catch {
            isRecording = false
        }
    }

    func stop() -> URL? {
        recorder?.stop()
        timer?.invalidate()
        timer = nil
        isRecording = false
        return fileURL
    }

    func cancel() {
        recorder?.stop()
        timer?.invalidate()
        timer = nil
        isRecording = false
        if let fileURL { try? FileManager.default.removeItem(at: fileURL) }
    }
}
