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

    /// A short "10s" / "30s" label for the duration chip.
    var durationLabel: String {
        if durationSeconds < 60 {
            return "\(durationSeconds)s"
        }
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"
    }

    /// A prayer is eligible to be shown when it has been reviewed, does not
    /// need review, and can actually be experienced in at least one mode.
    var isEligibleForToday: Bool {
        isReviewed && !needsReview && !availableModes.isEmpty
    }
}
