//
//  Profile.swift
//  PropPhone
//
//  A PhoneProfile is the complete identity of a character's phone:
//  who is in it, what it looks like, and what content lives on it.
//  Profiles are authored on the controller and replicated to prop
//  phones inside every PhoneState snapshot.
//

import Foundation

// MARK: - Asset reference

/// Content-addressed reference to a binary asset (audio, image) stored in `AssetStore`.
/// Only the ID travels over the wire; the bytes are transferred separately on demand.
struct AssetRef: Codable, Equatable, Hashable {
    /// Filename-safe identifier including extension, e.g. "3f9a1c07.m4a".
    var id: String
}

// MARK: - Phone profile

struct PhoneProfile: Codable, Equatable, Identifiable {
    var id: UUID
    /// Production-facing label, e.g. "Sofia — hero phone".
    var name: String
    var wallpaper: WallpaperSpec
    var statusBar: StatusBarSpec
    var contacts: [ContactCard]
    /// Contact IDs shown in the Phone app's Favorites tab, in order.
    var favorites: [UUID]
    var recents: [RecentCall]
    var voicemails: [VoicemailMessage]
    var threads: [MessageThread]
    /// The camera roll shown in the Photos app, newest first.
    var photos: [ImageSpec]

    init(
        id: UUID = UUID(),
        name: String,
        wallpaper: WallpaperSpec = .builtin("Wallpaper1"),
        statusBar: StatusBarSpec = StatusBarSpec(),
        contacts: [ContactCard] = [],
        favorites: [UUID] = [],
        recents: [RecentCall] = [],
        voicemails: [VoicemailMessage] = [],
        threads: [MessageThread] = [],
        photos: [ImageSpec] = []
    ) {
        self.id = id
        self.name = name
        self.wallpaper = wallpaper
        self.statusBar = statusBar
        self.contacts = contacts
        self.favorites = favorites
        self.recents = recents
        self.voicemails = voicemails
        self.threads = threads
        self.photos = photos
    }

    /// Tolerant decoding so documents saved by older builds keep loading
    /// as fields are added.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        wallpaper = try c.decodeIfPresent(WallpaperSpec.self, forKey: .wallpaper) ?? .builtin("Wallpaper1")
        statusBar = try c.decodeIfPresent(StatusBarSpec.self, forKey: .statusBar) ?? StatusBarSpec()
        contacts = try c.decodeIfPresent([ContactCard].self, forKey: .contacts) ?? []
        favorites = try c.decodeIfPresent([UUID].self, forKey: .favorites) ?? []
        recents = try c.decodeIfPresent([RecentCall].self, forKey: .recents) ?? []
        voicemails = try c.decodeIfPresent([VoicemailMessage].self, forKey: .voicemails) ?? []
        threads = try c.decodeIfPresent([MessageThread].self, forKey: .threads) ?? []
        photos = try c.decodeIfPresent([ImageSpec].self, forKey: .photos) ?? []
    }

    func contact(_ id: UUID?) -> ContactCard? {
        guard let id else { return nil }
        return contacts.first { $0.id == id }
    }

    func thread(_ id: UUID?) -> MessageThread? {
        guard let id else { return nil }
        return threads.first { $0.id == id }
    }

    /// All binary assets this profile depends on.
    var referencedAssets: Set<AssetRef> {
        var refs = Set<AssetRef>()
        if case .asset(let ref) = wallpaper { refs.insert(ref) }
        for c in contacts { if let ref = c.imageAsset { refs.insert(ref) } }
        for v in voicemails { if let ref = v.audioAsset { refs.insert(ref) } }
        for p in photos { if case .asset(let ref) = p { refs.insert(ref) } }
        return refs
    }
}

// MARK: - Appearance

enum WallpaperSpec: Codable, Equatable {
    /// Name of a bundled image set in Assets.xcassets (Wallpaper1...Wallpaper10).
    case builtin(String)
    /// Custom image imported by the production.
    case asset(AssetRef)
}

/// Any displayable image: bundled or production-imported. Same shape as a
/// wallpaper, reused for the Photos library.
typealias ImageSpec = WallpaperSpec

struct StatusBarSpec: Codable, Equatable {
    var carrierName: String = "N Telenor"
    /// 0...4
    var signalBars: Int = 4
    var showWiFi: Bool = true
    /// 0...100
    var batteryPercent: Int = 82
    var showBatteryPercent: Bool = false
}

// MARK: - Contacts

struct ContactCard: Codable, Equatable, Identifiable {
    var id: UUID
    var givenName: String
    var familyName: String
    /// Display number, free text so productions can use clearance-safe numbers.
    var phoneNumber: String
    /// Label under the name in call UI: "mobile", "work", ...
    var numberLabel: String
    var imageAsset: AssetRef?

    init(
        id: UUID = UUID(),
        givenName: String,
        familyName: String = "",
        phoneNumber: String = "",
        numberLabel: String = "mobile",
        imageAsset: AssetRef? = nil
    ) {
        self.id = id
        self.givenName = givenName
        self.familyName = familyName
        self.phoneNumber = phoneNumber
        self.numberLabel = numberLabel
        self.imageAsset = imageAsset
    }

    var displayName: String {
        let full = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
        return full.isEmpty ? phoneNumber : full
    }

    var monogram: String {
        let g = givenName.first.map(String.init) ?? ""
        let f = familyName.first.map(String.init) ?? ""
        let m = g + f
        return m.isEmpty ? "#" : m
    }
}

// MARK: - Recents

struct RecentCall: Codable, Equatable, Identifiable {
    var id: UUID
    /// Linked contact, or nil for an unknown number.
    var contactID: UUID?
    /// Shown when contactID is nil, e.g. "+47 982 12 331" or "Unknown".
    var displayName: String
    var subtitle: String
    var isMissed: Bool
    var isOutgoing: Bool
    var isFaceTime: Bool
    /// Free-text time label, e.g. "09:41", "Yesterday" — film-controlled, never live.
    var timeLabel: String

    init(
        id: UUID = UUID(),
        contactID: UUID? = nil,
        displayName: String = "",
        subtitle: String = "mobile",
        isMissed: Bool = false,
        isOutgoing: Bool = false,
        isFaceTime: Bool = false,
        timeLabel: String = "09:41"
    ) {
        self.id = id
        self.contactID = contactID
        self.displayName = displayName
        self.subtitle = subtitle
        self.isMissed = isMissed
        self.isOutgoing = isOutgoing
        self.isFaceTime = isFaceTime
        self.timeLabel = timeLabel
    }
}

// MARK: - Voicemail

struct VoicemailMessage: Codable, Equatable, Identifiable {
    var id: UUID
    /// Linked contact, or nil for an unknown caller.
    var contactID: UUID?
    /// Shown when contactID is nil.
    var displayName: String
    /// Secondary line: caller location or label, e.g. "Oslo, Norway" / "mobile".
    var subtitle: String
    /// Free-text date label, e.g. "Yesterday", "Tuesday", "6 August".
    var dateLabel: String
    /// Display duration in seconds; superseded by the real audio duration when audio exists.
    var duration: TimeInterval
    var audioAsset: AssetRef?
    var transcription: String?
    /// Whether the message starts out already listened-to in the scene baseline.
    var startsHeard: Bool

    init(
        id: UUID = UUID(),
        contactID: UUID? = nil,
        displayName: String = "",
        subtitle: String = "mobile",
        dateLabel: String = "Yesterday",
        duration: TimeInterval = 24,
        audioAsset: AssetRef? = nil,
        transcription: String? = nil,
        startsHeard: Bool = false
    ) {
        self.id = id
        self.contactID = contactID
        self.displayName = displayName
        self.subtitle = subtitle
        self.dateLabel = dateLabel
        self.duration = duration
        self.audioAsset = audioAsset
        self.transcription = transcription
        self.startsHeard = startsHeard
    }

    func resolvedName(in profile: PhoneProfile) -> String {
        profile.contact(contactID)?.displayName ?? (displayName.isEmpty ? "Unknown" : displayName)
    }
}

// MARK: - Messages

struct MessageThread: Codable, Equatable, Identifiable {
    var id: UUID
    /// Linked contact, or nil for an unknown number.
    var contactID: UUID?
    /// Shown when contactID is nil, e.g. "+47 21 00 44 90".
    var displayName: String
    var messages: [ChatMessage]
    /// Blue dot in the conversation list.
    var isUnread: Bool
    /// Animated typing bubble in the open thread (controller-cued).
    var isTyping: Bool

    init(
        id: UUID = UUID(),
        contactID: UUID? = nil,
        displayName: String = "",
        messages: [ChatMessage] = [],
        isUnread: Bool = false,
        isTyping: Bool = false
    ) {
        self.id = id
        self.contactID = contactID
        self.displayName = displayName
        self.messages = messages
        self.isUnread = isUnread
        self.isTyping = isTyping
    }

    func resolvedName(in profile: PhoneProfile) -> String {
        profile.contact(contactID)?.displayName ?? (displayName.isEmpty ? "Unknown" : displayName)
    }

    var previewText: String {
        messages.last?.text ?? ""
    }
}

struct ChatMessage: Codable, Equatable, Identifiable {
    var id: UUID
    var text: String
    var isOutgoing: Bool
    /// Optional centered separator shown above this message, e.g. "Today 09:12".
    var separatorLabel: String?

    init(id: UUID = UUID(), text: String, isOutgoing: Bool, separatorLabel: String? = nil) {
        self.id = id
        self.text = text
        self.isOutgoing = isOutgoing
        self.separatorLabel = separatorLabel
    }
}
