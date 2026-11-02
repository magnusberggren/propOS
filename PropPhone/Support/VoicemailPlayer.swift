//
//  VoicemailPlayer.swift
//  PropPhone
//
//  Audio playback for voicemail messages. When a message has no audio
//  asset yet (scratch content), playback is simulated so the scrubber
//  and timings still behave for rehearsal.
//

import AVFoundation
import Foundation
import Observation

@Observable
final class VoicemailPlayer: NSObject, AVAudioPlayerDelegate {
    private(set) var loadedMessageID: UUID?
    private(set) var isPlaying = false
    var progress: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var isSpeaker = true

    private var player: AVAudioPlayer?
    private var tick: Timer?
    /// True when there is no audio file and we simulate playback time.
    private var simulated = false

    func load(message: VoicemailMessage) {
        stop()
        loadedMessageID = message.id
        progress = 0
        if let ref = message.audioAsset,
           let p = try? AVAudioPlayer(contentsOf: AssetStore.shared.url(for: ref)) {
            player = p
            p.delegate = self
            p.prepareToPlay()
            duration = p.duration
            simulated = false
        } else {
            player = nil
            duration = max(message.duration, 1)
            simulated = true
        }
    }

    func togglePlay() {
        isPlaying ? pause() : play()
    }

    func play() {
        guard loadedMessageID != nil else { return }
        configureSession()
        if progress >= duration { progress = 0 }
        if !simulated {
            player?.currentTime = progress
            player?.play()
        }
        isPlaying = true
        startTick()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTick()
    }

    func stop() {
        player?.stop()
        player = nil
        stopTick()
        isPlaying = false
        loadedMessageID = nil
        progress = 0
        duration = 0
    }

    func seek(to time: TimeInterval) {
        progress = min(max(0, time), duration)
        if !simulated { player?.currentTime = progress }
    }

    func toggleSpeaker() {
        isSpeaker.toggle()
        configureSession()
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        // Speaker "on" is the natural choice on set: audible to camera and crew.
        try? session.setCategory(.playback, options: isSpeaker ? [] : [])
        try? session.setActive(true)
    }

    private func startTick() {
        stopTick()
        tick = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, self.isPlaying else { return }
            if self.simulated {
                self.progress += 0.1
                if self.progress >= self.duration {
                    self.progress = self.duration
                    self.pause()
                }
            } else if let p = self.player {
                self.progress = p.currentTime
            }
        }
    }

    private func stopTick() {
        tick?.invalidate()
        tick = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.progress = self.duration
            self.isPlaying = false
            self.stopTick()
        }
    }
}
