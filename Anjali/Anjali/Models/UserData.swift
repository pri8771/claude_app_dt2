import Foundation
import SwiftData

/// A record that a prayer was completed. Persisted with SwiftData so the
/// Today engine can deprioritise prayers already done today and the Me tab
/// can reflect a quiet history.
@Model
final class PrayerCompletion {
    /// Stable identifier of the prayer that was completed.
    var prayerID: String
    /// The mode the prayer was experienced in.
    var modeRawValue: String
    /// When it was completed.
    var completedAt: Date

    init(prayerID: String, mode: PlayMode, completedAt: Date) {
        self.prayerID = prayerID
        self.modeRawValue = mode.rawValue
        self.completedAt = completedAt
    }

    var mode: PlayMode {
        PlayMode(rawValue: modeRawValue) ?? .silent
    }
}

/// A prayer the user chose to keep. Persisted with SwiftData.
@Model
final class FavoritePrayer {
    /// Stable identifier of the saved prayer.
    @Attribute(.unique) var prayerID: String
    /// When it was saved.
    var savedAt: Date

    init(prayerID: String, savedAt: Date) {
        self.prayerID = prayerID
        self.savedAt = savedAt
    }
}
