import Foundation
import SwiftUI

/// In-memory store of all bundled prayers. Loaded once at launch from
/// `prayers.json`. Offline-first: there is no network path.
@MainActor
final class PrayerLibrary: ObservableObject {
    @Published private(set) var prayers: [Prayer]
    @Published private(set) var loadError: String?

    init(prayers: [Prayer]) {
        self.prayers = prayers
    }

    /// Load from the app bundle, degrading gracefully on failure.
    convenience init() {
        do {
            let loaded = try PrayerDataLoader.loadPrayers()
            self.init(prayers: loaded)
        } catch {
            self.init(prayers: [])
            self.loadError = "Prayers could not be loaded."
        }
    }

    /// Reviewed, experienceable prayers only.
    var reviewedPrayers: [Prayer] {
        prayers.filter { $0.isEligibleForToday }
    }

    func prayer(withID id: String) -> Prayer? {
        prayers.first { $0.id == id }
    }

    func prayers(for moment: Moment) -> [Prayer] {
        reviewedPrayers
            .filter { $0.moments.contains(moment) }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func prayers(for deity: Deity) -> [Prayer] {
        reviewedPrayers
            .filter { $0.deity == deity }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Moments that actually have at least one reviewed prayer.
    var availableMoments: [Moment] {
        Moment.allCases.filter { !prayers(for: $0).isEmpty }
    }

    /// Deities that actually have at least one reviewed prayer.
    var availableDeities: [Deity] {
        Deity.allCases.filter { !prayers(for: $0).isEmpty }
    }
}
