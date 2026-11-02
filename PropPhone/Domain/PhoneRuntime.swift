//
//  PhoneRuntime.swift
//  PropPhone
//
//  The prop phone's brain: owns the current PhoneState and applies both
//  remote cues (from the controller) and local interactions (from the
//  actor). Every mutation goes through here so the mirror report and
//  the renderer always agree.
//

import Foundation
import Observation
import UIKit

@Observable
final class PhoneRuntime {
    private(set) var state: PhoneState
    let audio: VoicemailPlayer
    /// Bumped when new asset bytes arrive so views re-resolve images.
    private(set) var assetGeneration = 0

    /// Called after any local (actor-driven) mutation — used for mirror reports.
    var onLocalMutation: ((PhoneState) -> Void)?

    init(state: PhoneState) {
        self.state = state
        self.audio = VoicemailPlayer()
    }

    // MARK: - External state (controller pushes, reset)

    func applyExternal(_ newState: PhoneState) {
        let ringingBefore = isRinging
        audio.stop()
        state = newState
        if isRinging && !ringingBefore { startRingingEffects() }
        if !isRinging { Haptics.stopRinging() }
    }

    func perform(_ action: CueAction) {
        let ringingBefore = isRinging
        state = PhoneStateReducer.apply(action, to: state)
        state.revision += 1
        if isRinging && !ringingBefore { startRingingEffects() }
        if !isRinging { Haptics.stopRinging() }
    }

    func assetsDidChange() {
        assetGeneration += 1
    }

    // MARK: - Actor interactions

    private func mutate(_ change: (inout PhoneState) -> Void) {
        change(&state)
        state.revision += 1
        onLocalMutation?(state)
    }

    private func mutatePhoneApp(_ change: (inout PhoneAppState) -> Void) {
        guard case .phoneApp(var app) = state.screen else { return }
        mutate { s in
            change(&app)
            s.screen = .phoneApp(app)
        }
    }

    // Lock screen

    func unlock() {
        guard state.screen == .lockScreen else { return }
        mutate { $0.screen = .home }
    }

    // Home screen

    func openPhoneApp() {
        mutate { $0.screen = .phoneApp(PhoneAppState(tab: .voicemail)) }
    }

    func openMessagesApp() {
        mutate { $0.screen = .messagesApp(MessagesAppState()) }
    }

    func openPhotosApp() {
        mutate { $0.screen = .photosApp(PhotosAppState()) }
    }

    func goHome() {
        audio.stop()
        mutate { $0.screen = .home }
    }

    // Messages app

    func openThread(_ threadID: UUID) {
        mutate { s in
            if let i = s.profile.threads.firstIndex(where: { $0.id == threadID }) {
                s.profile.threads[i].isUnread = false
            }
            s.screen = .messagesApp(MessagesAppState(openThreadID: threadID))
        }
    }

    func closeThread() {
        mutate { $0.screen = .messagesApp(MessagesAppState()) }
    }

    /// The actor typed a message on the real keyboard and hit send.
    func sendTypedMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              case .messagesApp(let app) = state.screen,
              let threadID = app.openThreadID else { return }
        mutate { s in
            if let i = s.profile.threads.firstIndex(where: { $0.id == threadID }) {
                s.profile.threads[i].messages.append(ChatMessage(text: trimmed, isOutgoing: true))
            }
        }
    }

    // Photos app

    func selectPhotosTab(_ tab: PhotosTab) {
        mutate { $0.screen = .photosApp(PhotosAppState(tab: tab)) }
    }

    func openPhoto(at index: Int) {
        mutate { $0.screen = .photosApp(PhotosAppState(tab: .library, openPhotoIndex: index)) }
    }

    func setOpenPhotoIndex(_ index: Int) {
        guard case .photosApp(var app) = state.screen, app.openPhotoIndex != nil else { return }
        mutate { s in
            app.openPhotoIndex = index
            s.screen = .photosApp(app)
        }
    }

    func closePhotoViewer() {
        mutate { $0.screen = .photosApp(PhotosAppState(tab: .library)) }
    }

    // Phone app

    func selectTab(_ tab: PhoneTab) {
        audio.stop()
        mutatePhoneApp { app in
            app.tab = tab
            app.expandedVoicemailID = nil
        }
    }

    func toggleRecentsMissed(_ missedOnly: Bool) {
        mutatePhoneApp { $0.recentsShowsMissed = missedOnly }
    }

    func keypadAppend(_ digit: String) {
        mutatePhoneApp { $0.keypadDigits.append(digit) }
    }

    func keypadDeleteLast() {
        mutatePhoneApp { if !$0.keypadDigits.isEmpty { $0.keypadDigits.removeLast() } }
    }

    // Voicemail

    func tapVoicemail(_ message: VoicemailMessage) {
        guard case .phoneApp(let app) = state.screen else { return }
        if app.expandedVoicemailID == message.id {
            audio.stop()
            mutatePhoneApp { $0.expandedVoicemailID = nil }
        } else {
            mutatePhoneApp { $0.expandedVoicemailID = message.id }
            mutate { $0.heardVoicemailIDs.insert(message.id) }
            audio.load(message: message)
        }
    }

    func deleteVoicemail(_ message: VoicemailMessage) {
        audio.stop()
        mutate { s in
            s.profile.voicemails.removeAll { $0.id == message.id }
            if case .phoneApp(var app) = s.screen, app.expandedVoicemailID == message.id {
                app.expandedVoicemailID = nil
                s.screen = .phoneApp(app)
            }
        }
    }

    func callBack(from message: VoicemailMessage) {
        audio.stop()
        let name = message.resolvedName(in: state.profile)
        let image = state.profile.contact(message.contactID)?.imageAsset
        mutate { s in
            s.screen = .activeCall(ActiveCallState(
                callerName: name, callerImageAsset: image, connectedAt: Date()
            ))
        }
    }

    // Calls

    var isRinging: Bool {
        if case .incomingCall = state.screen { return true }
        return false
    }

    func answerCall() {
        guard case .incomingCall(let spec) = state.screen else { return }
        Haptics.stopRinging()
        mutate { s in
            s.screen = .activeCall(ActiveCallState(
                callerName: spec.callerName,
                callerImageAsset: spec.callerImageAsset,
                connectedAt: Date()
            ))
        }
    }

    func declineCall() {
        guard case .incomingCall = state.screen else { return }
        Haptics.stopRinging()
        mutate { s in
            s.screen = s.resumeScreen ?? .lockScreen
            s.resumeScreen = nil
        }
    }

    func endCall() {
        guard case .activeCall = state.screen else { return }
        mutate { s in
            s.screen = s.resumeScreen ?? .lockScreen
            s.resumeScreen = nil
        }
    }

    private func startRingingEffects() {
        if case .incomingCall(let spec) = state.screen, spec.vibrate {
            Haptics.startRinging()
        }
    }
}

// MARK: - Reducer

/// Pure application of cue actions to a state. Used by the controller
/// (before pushing) and by solo mode — same semantics everywhere.
enum PhoneStateReducer {
    static func apply(_ action: CueAction, to state: PhoneState) -> PhoneState {
        var s = state
        switch action {
        case .setScreen(let screen):
            s.screen = screen
            s.resumeScreen = nil
        case .incomingCall(let spec):
            if case .incomingCall = s.screen {
                // Replace the ringing call without stacking resume screens.
            } else {
                s.resumeScreen = s.screen
            }
            s.screen = .incomingCall(spec)
        case .notification(let item):
            s.lockNotifications.insert(item, at: 0)
        case .clearNotifications:
            s.lockNotifications.removeAll()
        case .setClock(let clock):
            s.clock = clock
        case .blackout(let on):
            s.blackout = on
        case .incomingText(let threadID, let text):
            guard let i = s.profile.threads.firstIndex(where: { $0.id == threadID }) else { break }
            s.profile.threads[i].messages.append(ChatMessage(text: text, isOutgoing: false))
            s.profile.threads[i].isTyping = false
            let threadIsOpen = s.screen == .messagesApp(MessagesAppState(openThreadID: threadID))
            if !threadIsOpen {
                s.profile.threads[i].isUnread = true
            }
            if s.screen == .lockScreen {
                s.lockNotifications.insert(NotificationItem(
                    app: .messages,
                    title: s.profile.threads[i].resolvedName(in: s.profile),
                    body: text
                ), at: 0)
            }
        case .setTyping(let threadID, let isTyping):
            guard let i = s.profile.threads.firstIndex(where: { $0.id == threadID }) else { break }
            s.profile.threads[i].isTyping = isTyping
        }
        return s
    }
}

// MARK: - Haptics

enum Haptics {
    private static var ringTimer: Timer?

    /// Approximates the iPhone ring vibration cadence.
    static func startRinging() {
        stopRinging()
        vibrateBurst()
        ringTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            vibrateBurst()
        }
    }

    static func stopRinging() {
        ringTimer?.invalidate()
        ringTimer = nil
    }

    private static func vibrateBurst() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            generator.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            generator.impactOccurred()
        }
    }
}
