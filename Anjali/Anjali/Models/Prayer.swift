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

    /// The modes a user can actually start. Every prayer is always completable
    /// in Silent (read-only), so a prayer with no listed modes — or one whose
    /// only modes depend on missing audio — still degrades gracefully rather
    /// than blocking. Listen falls back to timed text when audio is absent.
    var playableModes: [PlayMode] {
        availableModes.isEmpty ? [.silent] : availableModes
    }

    /// A prayer is eligible to be shown when it has been reviewed and does not
    /// need review. It is always completable (at minimum in Silent), so the
    /// presence of modes/audio never excludes it.
    var isEligibleForToday: Bool {
        isReviewed && !needsReview
    }
}
