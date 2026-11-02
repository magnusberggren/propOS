//
//  PhoneState.swift
//  PropPhone
//
//  PhoneState is the single replicated truth of what a prop phone shows.
//  The controller pushes whole snapshots; the phone renders whatever
//  snapshot it last received and reports its own snapshot back after
//  local (actor) interactions. Because state is total and idempotent,
//  reconnects and "reset to baseline" are trivially correct.
//

import Foundation

struct PhoneState: Codable, Equatable {
    /// Monotonic revision for debugging/ordering; last writer wins.
    var revision: Int
    var profile: PhoneProfile
    var clock: ClockSpec
    var screen: ScreenState
    /// Screen to return to when an incoming call is declined or ends.
    var resumeScreen: ScreenState?
    var lockNotifications: [NotificationItem]
    /// Voicemail IDs the character has listened to.
    var heardVoicemailIDs: Set<UUID>
    /// Hard black screen (phone "off" / pocket shot).
    var blackout: Bool

    init(profile: PhoneProfile) {
        self.revision = 0
        self.profile = profile
        self.clock = .live
        self.screen = .lockScreen
        self.resumeScreen = nil
        self.lockNotifications = []
        self.heardVoicemailIDs = Set(profile.voicemails.filter(\.startsHeard).map(\.id))
        self.blackout = false
    }

    var unheardVoicemailCount: Int {
        profile.voicemails.filter { !heardVoicemailIDs.contains($0.id) }.count
    }

    var referencedAssets: Set<AssetRef> {
        var refs = profile.referencedAssets
        if case .incomingCall(let spec) = screen, let ref = spec.callerImageAsset {
            refs.insert(ref)
        }
        return refs
    }
}

// MARK: - Clock

/// Display time as a spec rather than a ticking value, so devices never drift.
enum ClockSpec: Codable, Equatable {
    /// Real wall-clock time.
    case live
    /// Fixed display time; never advances. The workhorse for continuity.
    case frozen(Date)
    /// Wall clock shifted by a fixed offset (scene set at 03:12, shot at noon).
    case offset(TimeInterval)

    func displayTime(at now: Date = Date()) -> Date {
        switch self {
        case .live: return now
        case .frozen(let date): return date
        case .offset(let delta): return now.addingTimeInterval(delta)
        }
    }
}

// MARK: - Screens

enum ScreenState: Codable, Equatable {
    case off
    case lockScreen
    case home
    case phoneApp(PhoneAppState)
    case messagesApp(MessagesAppState)
    case photosApp(PhotosAppState)
    case incomingCall(CallSpec)
    case activeCall(ActiveCallState)
}

struct MessagesAppState: Codable, Equatable {
    /// Open thread, or nil for the conversation list.
    var openThreadID: UUID?

    init(openThreadID: UUID? = nil) {
        self.openThreadID = openThreadID
    }
}

enum PhotosTab: String, Codable {
    case library, forYou, albums, search
}

struct PhotosAppState: Codable, Equatable {
    var tab: PhotosTab = .library
    /// Index into the profile's photo library when the viewer is open.
    var openPhotoIndex: Int?

    init(tab: PhotosTab = .library, openPhotoIndex: Int? = nil) {
        self.tab = tab
        self.openPhotoIndex = openPhotoIndex
    }
}

enum PhoneTab: String, Codable, CaseIterable {
    case favorites, recents, contacts, keypad, voicemail
}

struct PhoneAppState: Codable, Equatable {
    var tab: PhoneTab = .voicemail
    var expandedVoicemailID: UUID?
    var keypadDigits: String = ""
    var recentsShowsMissed: Bool = false
}

// MARK: - Calls

enum CallPresentation: String, Codable {
    /// Locked-phone look: "slide to answer".
    case slider
    /// Unlocked look: round Decline / Accept buttons.
    case buttons
}

struct CallSpec: Codable, Equatable {
    var callerName: String
    /// Line under the name: "mobile", "Oslo, Norway", a number...
    var callerSubtitle: String
    var callerImageAsset: AssetRef?
    var isFaceTime: Bool
    var presentation: CallPresentation
    var vibrate: Bool

    init(
        callerName: String,
        callerSubtitle: String = "mobile",
        callerImageAsset: AssetRef? = nil,
        isFaceTime: Bool = false,
        presentation: CallPresentation = .slider,
        vibrate: Bool = true
    ) {
        self.callerName = callerName
        self.callerSubtitle = callerSubtitle
        self.callerImageAsset = callerImageAsset
        self.isFaceTime = isFaceTime
        self.presentation = presentation
        self.vibrate = vibrate
    }

    static func from(contact: ContactCard, presentation: CallPresentation = .slider) -> CallSpec {
        CallSpec(
            callerName: contact.displayName,
            callerSubtitle: contact.numberLabel,
            callerImageAsset: contact.imageAsset,
            presentation: presentation
        )
    }
}

struct ActiveCallState: Codable, Equatable {
    var callerName: String
    var callerImageAsset: AssetRef?
    /// Wall-clock moment the call "connected"; the on-screen timer derives from it.
    var connectedAt: Date
}

// MARK: - Notifications

/// Built-in fake app identities for notification banners.
enum FakeApp: String, Codable, CaseIterable {
    case messages, mail, phone, calendar, photos, bank

    var displayName: String {
        switch self {
        case .messages: return "Messages"
        case .mail: return "Mail"
        case .phone: return "Phone"
        case .calendar: return "Calendar"
        case .photos: return "Photos"
        case .bank: return "Bank"
        }
    }
}

struct NotificationItem: Codable, Equatable, Identifiable {
    var id: UUID
    var app: FakeApp
    var title: String
    var body: String
    /// Free-text age label shown top-right of the banner: "now", "5m ago", "09:41".
    var timeLabel: String

    init(
        id: UUID = UUID(),
        app: FakeApp = .messages,
        title: String,
        body: String,
        timeLabel: String = "now"
    ) {
        self.id = id
        self.app = app
        self.title = title
        self.body = body
        self.timeLabel = timeLabel
    }
}
