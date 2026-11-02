//
//  PropPhoneTests.swift
//  PropPhoneTests
//
//  State spine invariants: snapshot codec, reducer semantics,
//  reset-to-baseline, clock math, and asset addressing.
//

import Foundation
import Testing
@testable import PropPhone

struct StateCodecTests {
    @Test func phoneStateRoundTripsThroughJSON() throws {
        var state = PhoneState(profile: sampleProfile())
        state.clock = .frozen(Date(timeIntervalSince1970: 1_780_000_000))
        state.screen = .phoneApp(PhoneAppState(tab: .voicemail, expandedVoicemailID: nil, keypadDigits: "112"))
        state.lockNotifications = [NotificationItem(app: .messages, title: "A", body: "B")]

        let data = try JSONCoding.encoder.encode(state)
        let decoded = try JSONCoding.decoder.decode(PhoneState.self, from: data)
        #expect(decoded == state)
    }

    @Test func showDocumentRoundTrips() throws {
        let doc = ShowStore.seedDocument()
        let data = try JSONCoding.encoder.encode(doc)
        let decoded = try JSONCoding.decoder.decode(ShowDocument.self, from: data)
        #expect(decoded == doc)
    }
}

struct ReducerTests {
    @Test func incomingCallStoresResumeScreen() {
        var state = PhoneState(profile: sampleProfile())
        state.screen = .phoneApp(PhoneAppState(tab: .voicemail))

        let spec = CallSpec(callerName: "Mari")
        let ringing = PhoneStateReducer.apply(.incomingCall(spec), to: state)

        #expect(ringing.screen == .incomingCall(spec))
        #expect(ringing.resumeScreen == .phoneApp(PhoneAppState(tab: .voicemail)))
    }

    @Test func replacingARingingCallKeepsOriginalResumeScreen() {
        var state = PhoneState(profile: sampleProfile())
        state.screen = .home

        let first = PhoneStateReducer.apply(.incomingCall(CallSpec(callerName: "A")), to: state)
        let second = PhoneStateReducer.apply(.incomingCall(CallSpec(callerName: "B")), to: first)

        #expect(second.resumeScreen == .home)
    }

    @Test func notificationsInsertNewestFirst() {
        var state = PhoneState(profile: sampleProfile())
        state = PhoneStateReducer.apply(.notification(NotificationItem(title: "first", body: "")), to: state)
        state = PhoneStateReducer.apply(.notification(NotificationItem(title: "second", body: "")), to: state)

        #expect(state.lockNotifications.map(\.title) == ["second", "first"])
    }

    @Test func incomingTextIntoOpenThreadAppendsWithoutUnread() {
        let profile = sampleProfile()
        let thread = profile.threads[0]
        var state = PhoneState(profile: profile)
        state.screen = .messagesApp(MessagesAppState(openThreadID: thread.id))

        state = PhoneStateReducer.apply(.incomingText(threadID: thread.id, text: "hey"), to: state)

        let updated = state.profile.thread(thread.id)!
        #expect(updated.messages.last?.text == "hey")
        #expect(updated.messages.last?.isOutgoing == false)
        #expect(!updated.isUnread)
        #expect(state.lockNotifications.isEmpty)
    }

    @Test func incomingTextOnLockScreenBannersAndMarksUnread() {
        let profile = sampleProfile()
        let thread = profile.threads[0]
        var state = PhoneState(profile: profile)
        state.screen = .lockScreen

        state = PhoneStateReducer.apply(.incomingText(threadID: thread.id, text: "call me"), to: state)

        #expect(state.profile.thread(thread.id)!.isUnread)
        #expect(state.lockNotifications.first?.body == "call me")
        #expect(state.lockNotifications.first?.app == .messages)
    }

    @Test func incomingTextClearsTypingIndicator() {
        let profile = sampleProfile()
        let thread = profile.threads[0]
        var state = PhoneState(profile: profile)

        state = PhoneStateReducer.apply(.setTyping(threadID: thread.id, isTyping: true), to: state)
        #expect(state.profile.thread(thread.id)!.isTyping)

        state = PhoneStateReducer.apply(.incomingText(threadID: thread.id, text: "done typing"), to: state)
        #expect(!state.profile.thread(thread.id)!.isTyping)
    }
}

struct LegacyDecodingTests {
    /// Profiles saved before threads/photos existed must keep decoding.
    @Test func profileWithoutNewFieldsDecodesWithDefaults() throws {
        var old = sampleProfile()
        old.threads = []
        old.photos = []
        var json = try JSONSerialization.jsonObject(
            with: JSONCoding.encoder.encode(old)
        ) as! [String: Any]
        json.removeValue(forKey: "threads")
        json.removeValue(forKey: "photos")

        let data = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONCoding.decoder.decode(PhoneProfile.self, from: data)

        #expect(decoded.threads.isEmpty)
        #expect(decoded.photos.isEmpty)
        #expect(decoded.id == old.id)
        #expect(decoded.voicemails.count == old.voicemails.count)
    }
}

struct ResetSemanticsTests {
    @Test func baselineRestoresHeardStateAndScreen() {
        let profile = sampleProfile()
        var baseline = PhoneState(profile: profile)
        baseline.screen = .phoneApp(PhoneAppState(tab: .voicemail))

        // Simulate a take: actor listens to a message and wanders off.
        let runtime = PhoneRuntime(state: baseline)
        let message = profile.voicemails[0]
        runtime.tapVoicemail(message)
        runtime.selectTab(.recents)

        #expect(runtime.state.heardVoicemailIDs.contains(message.id))
        #expect(runtime.state != baseline)

        // RESET: exactly the baseline again, in one apply.
        runtime.applyExternal(baseline)
        var expected = baseline
        expected.revision = runtime.state.revision
        #expect(runtime.state == expected)
        #expect(!runtime.state.heardVoicemailIDs.contains(message.id))
    }

    @Test func initialHeardSetComesFromStartsHeard() {
        let profile = sampleProfile()
        let state = PhoneState(profile: profile)
        let heardByAuthor = Set(profile.voicemails.filter(\.startsHeard).map(\.id))
        #expect(state.heardVoicemailIDs == heardByAuthor)
        #expect(state.unheardVoicemailCount == profile.voicemails.count - heardByAuthor.count)
    }
}

struct ClockTests {
    @Test func frozenClockNeverAdvances() {
        let moment = Date(timeIntervalSince1970: 1_780_000_000)
        let clock = ClockSpec.frozen(moment)
        #expect(clock.displayTime(at: moment.addingTimeInterval(9999)) == moment)
    }

    @Test func offsetClockTracksWallClock() {
        let now = Date()
        let clock = ClockSpec.offset(-3600)
        #expect(abs(clock.displayTime(at: now).timeIntervalSince(now) + 3600) < 0.001)
    }
}

struct AssetStoreTests {
    @Test func identicalDataProducesIdenticalRef() throws {
        let store = AssetStore()
        let data = Data("same bytes".utf8)
        let a = try store.store(data: data, fileExtension: "m4a")
        let b = try store.store(data: data, fileExtension: "m4a")
        #expect(a == b)
        #expect(store.exists(a))
    }
}

// MARK: - Fixtures

private func sampleProfile() -> PhoneProfile {
    let mari = ContactCard(givenName: "Mari", familyName: "Holm", phoneNumber: "+47 982 44 310")
    var profile = PhoneProfile(name: "Test phone", contacts: [mari])
    profile.voicemails = [
        VoicemailMessage(contactID: mari.id, dateLabel: "09:12", duration: 30),
        VoicemailMessage(displayName: "Unknown", dateLabel: "Yesterday", duration: 10, startsHeard: true)
    ]
    profile.threads = [
        MessageThread(contactID: mari.id, messages: [
            ChatMessage(text: "Lunch tomorrow?", isOutgoing: false, separatorLabel: "Yesterday 12:31")
        ])
    ]
    return profile
}
