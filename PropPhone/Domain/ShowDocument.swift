//
//  ShowDocument.swift
//  PropPhone
//
//  The production document: phone profiles and scenes with their
//  baseline states and cues. Persisted as JSON in Documents so a
//  future version can share .propshow files between devices.
//

import Foundation
import Observation

struct ShowDocument: Codable, Equatable {
    var phones: [PhoneProfile] = []
    var scenes: [SceneSetup] = []
}

/// A scene binds a phone profile to a continuity baseline and a cue list.
struct SceneSetup: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var phoneID: UUID
    /// The exact PhoneState every take starts from. RESET re-applies this.
    var baseline: PhoneState
    var cues: [Cue]

    init(id: UUID = UUID(), name: String, phoneID: UUID, baseline: PhoneState, cues: [Cue] = []) {
        self.id = id
        self.name = name
        self.phoneID = phoneID
        self.baseline = baseline
        self.cues = cues
    }
}

struct Cue: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var action: CueAction

    init(id: UUID = UUID(), name: String, action: CueAction) {
        self.id = id
        self.name = name
        self.action = action
    }
}

enum CueAction: Codable, Equatable {
    case setScreen(ScreenState)
    case incomingCall(CallSpec)
    case notification(NotificationItem)
    case clearNotifications
    case setClock(ClockSpec)
    case blackout(Bool)
    /// A text arrives in a thread: appended live if the thread is open,
    /// otherwise unread dot + lock-screen banner.
    case incomingText(threadID: UUID, text: String)
    /// Toggle the animated typing bubble in a thread.
    case setTyping(threadID: UUID, isTyping: Bool)
}

// MARK: - Store

@Observable
final class ShowStore {
    private(set) var document: ShowDocument

    private let fileURL: URL

    init(filename: String = "show.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = docs.appendingPathComponent(filename)
        if let data = try? Data(contentsOf: fileURL),
           let doc = try? JSONCoding.decoder.decode(ShowDocument.self, from: data) {
            self.document = doc
        } else {
            self.document = ShowStore.seedDocument()
            save()
        }
    }

    // MARK: Mutation

    func upsertPhone(_ phone: PhoneProfile) {
        if let i = document.phones.firstIndex(where: { $0.id == phone.id }) {
            document.phones[i] = phone
            // Keep scene baselines in sync with the edited profile so RESET
            // reflects the latest authored content.
            for s in document.scenes.indices where document.scenes[s].phoneID == phone.id {
                document.scenes[s].baseline.profile = phone
                document.scenes[s].baseline.heardVoicemailIDs = Set(
                    phone.voicemails.filter(\.startsHeard).map(\.id)
                )
            }
        } else {
            document.phones.append(phone)
        }
        save()
    }

    func deletePhone(id: UUID) {
        document.phones.removeAll { $0.id == id }
        document.scenes.removeAll { $0.phoneID == id }
        save()
    }

    func upsertScene(_ scene: SceneSetup) {
        if let i = document.scenes.firstIndex(where: { $0.id == scene.id }) {
            document.scenes[i] = scene
        } else {
            document.scenes.append(scene)
        }
        save()
    }

    func deleteScene(id: UUID) {
        document.scenes.removeAll { $0.id == id }
        save()
    }

    func phone(_ id: UUID?) -> PhoneProfile? {
        guard let id else { return nil }
        return document.phones.first { $0.id == id }
    }

    func save() {
        if let data = try? JSONCoding.encoder.encode(document) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: Seed content

    /// A ready-to-shoot example production so the app is demonstrable on first launch.
    static func seedDocument() -> ShowDocument {
        let mari = ContactCard(givenName: "Mari", familyName: "Holm", phoneNumber: "+47 982 44 310")
        let jonas = ContactCard(givenName: "Jonas", familyName: "Berg", phoneNumber: "+47 913 22 874")
        let mamma = ContactCard(givenName: "Mamma", phoneNumber: "+47 901 18 220")
        let dahl = ContactCard(givenName: "Dr.", familyName: "Dahl", phoneNumber: "+47 22 93 40 10", numberLabel: "work")
        let eirik = ContactCard(givenName: "Eirik", familyName: "Sand", phoneNumber: "+47 977 65 401")

        var phone = PhoneProfile(
            name: "Sofia — hero phone",
            wallpaper: .builtin("Wallpaper3"),
            statusBar: StatusBarSpec(carrierName: "N Telenor", signalBars: 3, showWiFi: true, batteryPercent: 71),
            contacts: [mari, jonas, mamma, dahl, eirik]
        )
        phone.favorites = [mamma.id, mari.id, jonas.id]
        phone.recents = [
            RecentCall(contactID: mari.id, subtitle: "mobile", isMissed: true, timeLabel: "09:12"),
            RecentCall(displayName: "+47 21 00 44 90", subtitle: "Oslo, Norway", isMissed: true, timeLabel: "08:47"),
            RecentCall(contactID: mamma.id, subtitle: "mobile", isOutgoing: true, timeLabel: "Yesterday"),
            RecentCall(contactID: jonas.id, subtitle: "FaceTime", isFaceTime: true, timeLabel: "Yesterday"),
            RecentCall(contactID: dahl.id, subtitle: "work", isMissed: true, timeLabel: "Tuesday")
        ]
        phone.voicemails = [
            VoicemailMessage(
                contactID: mamma.id,
                subtitle: "mobile",
                dateLabel: "09:12",
                duration: 31,
                transcription: "Hei vennen, det er mamma. Kan du ringe meg når du hører dette? Det gjelder pappa. Det er ikke farlig, men... ring meg.",
                startsHeard: false
            ),
            VoicemailMessage(
                contactID: dahl.id,
                subtitle: "work",
                dateLabel: "Yesterday",
                duration: 18,
                transcription: "This is Dr. Dahl's office calling about the results from Tuesday. Please call us back at your earliest convenience.",
                startsHeard: false
            ),
            VoicemailMessage(
                displayName: "Unknown",
                subtitle: "Oslo, Norway",
                dateLabel: "Yesterday",
                duration: 9,
                transcription: nil,
                startsHeard: false
            ),
            VoicemailMessage(
                contactID: jonas.id,
                subtitle: "mobile",
                dateLabel: "Tuesday",
                duration: 42,
                transcription: "Hey, it's me. I know you said you needed space, but... just call me back, okay?",
                startsHeard: true
            )
        ]

        let jonasThread = MessageThread(
            contactID: jonas.id,
            messages: [
                ChatMessage(text: "I know you said you needed space", isOutgoing: false,
                            separatorLabel: "Tuesday 21:04"),
                ChatMessage(text: "but I left you a voicemail. Please just listen to it", isOutgoing: false),
                ChatMessage(text: "ok", isOutgoing: true),
                ChatMessage(text: "ok as in you'll listen?", isOutgoing: false)
            ]
        )
        let mariThread = MessageThread(
            contactID: mari.id,
            messages: [
                ChatMessage(text: "Lunch tomorrow?", isOutgoing: false, separatorLabel: "Yesterday 12:31"),
                ChatMessage(text: "Can't, I'll call you", isOutgoing: true),
                ChatMessage(text: "you okay??", isOutgoing: false)
            ],
            isUnread: true
        )
        let mammaThread = MessageThread(
            contactID: mamma.id,
            messages: [
                ChatMessage(text: "Ring meg når du kan ❤️", isOutgoing: false,
                            separatorLabel: "Today 09:14")
            ],
            isUnread: true
        )
        phone.threads = [mammaThread, mariThread, jonasThread]
        phone.photos = (1...10).map { .builtin("Wallpaper\($0)") }

        var baseline = PhoneState(profile: phone)
        baseline.clock = .frozen(DateComponents(
            calendar: .current, year: 2026, month: 8, day: 6, hour: 9, minute: 41
        ).date ?? Date())
        baseline.screen = .phoneApp(PhoneAppState(tab: .voicemail))

        let scene = SceneSetup(
            name: "Sc. 42 — Sofia checks voicemail",
            phoneID: phone.id,
            baseline: baseline,
            cues: [
                Cue(name: "Incoming: Mari", action: .incomingCall(.from(contact: mari))),
                Cue(name: "Jonas is typing…", action: .setTyping(threadID: jonasThread.id, isTyping: true)),
                Cue(name: "Text from Jonas", action: .incomingText(
                    threadID: jonasThread.id, text: "Did you listen to it yet?"
                )),
                Cue(name: "Back to lock screen", action: .setScreen(.lockScreen))
            ]
        )

        return ShowDocument(phones: [phone], scenes: [scene])
    }
}

// MARK: - JSON

enum JSONCoding {
    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
