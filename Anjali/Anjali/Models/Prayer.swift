import Foundation

/// The sacred text of a prayer in its primary script (Devanagari) plus an
/// optional secondary line. Kept as its own type so additional scripts or
/// metadata can be added without touching `Prayer`.
struct PrayerText: Codable, Hashable {
    /// The mantra in Devanagari script.
    let devanagari: String

    init(devanagari: String) {
        self.devanagari = devanagari
    }
}

/// Sourcing + human-review trail for a prayer's sacred text. `reviewer` and
/// `reviewedOn` stay empty until a *named* human (cultural / theological)
/// reviewer signs off. Release is gated on that sign-off — see
/// `Scripts/validate_prayers.py --require-signoff` and `.github/workflows/release-gate.yml`.
/// This is the executable form of the content-integrity guarantee in
/// `CONTENT_GUIDELINES.md`.
struct Provenance: Codable, Hashable {
    /// A specific scriptural / traditional citation for the text (best-effort,
    /// still subject to the human sign-off below).
    let sourceReference: String
    /// The named human who reviewed and approved this text. Empty (or the
    /// placeholder `"seed"`) means *not yet* signed off.
    let reviewer: String
    /// ISO-8601 date the sign-off was recorded. Empty until reviewed.
    let reviewedOn: String

    /// The "not yet reviewed" sentinel. Used as the model default so older
    /// call sites/tests keep compiling; real prayers carry their decoded
    /// provenance, and the release gate blocks anything still `.unsigned`.
    static let unsigned = Provenance(sourceReference: "", reviewer: "", reviewedOn: "")

    /// True only when a named human has recorded a sign-off. The release gate
    /// refuses to ship any prayer where this is false.
    var isHumanSignedOff: Bool {
        let name = reviewer.trimmingCharacters(in: .whitespaces).lowercased()
        return !name.isEmpty
            && name != "seed"
            && !reviewedOn.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

/// A single micro-prayer. This is immutable reference content loaded from the
/// bundled `prayers.json`; it is *not* a SwiftData model. User-generated state
/// (completions, favorites) lives in separate SwiftData models.
struct Prayer: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    /// The deity addressed, if any. Universal Upanishadic mantras (e.g. the
    /// peace invocations) are not addressed to a single deity and leave this nil.
    let deity: Deity?
    let moments: [Moment]
    let intentions: [Intention]
    let timeContexts: [TimeContext]
    let durationSeconds: Int
    let availableModes: [PlayMode]
    let primaryText: PrayerText
    let transliteration: String
    let meaning: String
    let sourceTitle: String
    /// Sourcing + human-review trail. Every shipped prayer must carry a citation,
    /// and release is gated on a named human sign-off (`provenance.isHumanSignedOff`).
    /// Defaults to `.unsigned` so existing memberwise-init call sites keep compiling;
    /// real prayers decode their provenance from `prayers.json`, and the
    /// content-validator/release gate enforce presence + sign-off.
    var provenance: Provenance = .unsigned
    let audioAssetName: String?
    let isReviewed: Bool
    let needsReview: Bool
    let isFeatured: Bool
    let sortOrder: Int
    /// How often this prayer should surface on Today. See `RotationPolicy`.
    let rotationPolicy: RotationPolicy

    /// A short "10s" / "30s" label for the duration chip.
    var durationLabel: String {
        if durationSeconds < 60 {
            return "\(durationSeconds)s"
        }
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"
    }

    /// A spelled-out duration for VoiceOver (e.g. "12 seconds", "1 minute 30
    /// seconds") so it isn't read as "twelve s".
    var accessibleDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        func plural(_ n: Int, _ unit: String) -> String { "\(n) \(unit)\(n == 1 ? "" : "s")" }
        if minutes == 0 { return plural(seconds, "second") }
        if seconds == 0 { return plural(minutes, "minute") }
        return "\(plural(minutes, "minute")) \(plural(seconds, "second"))"
    }

    /// The modes a user can actually start. Every prayer is always completable
    /// in Silent (read-only), so Silent is guaranteed to be present even if it
    /// wasn't listed — and a prayer with no listed modes still degrades to
    /// Silent rather than blocking. Listen falls back to timed text when audio
    /// is absent.
    var playableModes: [PlayMode] {
        var modes = availableModes
        if !modes.contains(.silent) { modes.append(.silent) }
        return modes
    }

    /// A prayer is eligible to be shown when it has been reviewed and does not
    /// need review. It is always completable (at minimum in Silent), so the
    /// presence of modes/audio never excludes it.
    var isEligibleForToday: Bool {
        isReviewed && !needsReview
    }
}
