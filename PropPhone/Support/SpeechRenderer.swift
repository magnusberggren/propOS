//
//  SpeechRenderer.swift
//  PropPhone
//
//  Generates scratch voicemail audio from a transcription using
//  on-device TTS, so a scene is rehearsable before the real actor
//  records the message.
//

import AVFoundation
import Foundation

enum SpeechRenderer {
    /// Renders `text` to a CAF file and stores it as an asset.
    static func renderScratchAudio(
        text: String,
        languageCode: String? = nil,
        completion: @escaping (Result<AssetRef, Error>) -> Void
    ) {
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: text)
        if let languageCode, let voice = AVSpeechSynthesisVoice(language: languageCode) {
            utterance.voice = voice
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("caf")

        var audioFile: AVAudioFile?
        // Retain the synthesizer until writing completes.
        var retained: AVSpeechSynthesizer? = synthesizer

        synthesizer.write(utterance) { buffer in
            guard let pcm = buffer as? AVAudioPCMBuffer else { return }
            if pcm.frameLength == 0 {
                // Zero-length buffer signals the end of synthesis.
                defer { retained = nil; _ = retained }
                do {
                    guard audioFile != nil else {
                        throw NSError(domain: "SpeechRenderer", code: 2, userInfo: [
                            NSLocalizedDescriptionKey: "No audio was generated."
                        ])
                    }
                    audioFile = nil
                    let ref = try AssetStore.shared.importFile(at: tempURL)
                    try? FileManager.default.removeItem(at: tempURL)
                    DispatchQueue.main.async { completion(.success(ref)) }
                } catch {
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
                return
            }
            do {
                if audioFile == nil {
                    audioFile = try AVAudioFile(forWriting: tempURL, settings: pcm.format.settings)
                }
                try audioFile?.write(from: pcm)
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }
}
