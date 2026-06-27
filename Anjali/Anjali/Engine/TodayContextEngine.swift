import Foundation

/// Deterministic engine that selects the single prayer to surface on Today.
///
/// Scoring (per the product spec):
/// - `+100` the prayer matches an **explicitly** chosen moment
/// - `+60`  the prayer matches an **inferred** moment (from the time band or a
///          favourited moment)
/// - `+35`  the prayer's time contexts include the current band
/// - `+40`  the prayer's deity matches the user's preferred (ishta) deity
/// - `-100` the prayer needs review
/// - `-50`  the prayer was already completed today
/// - `-1000` the prayer has no available mode (cannot be experienced)
///
/// `needsReview` and mode-less prayers are also **hard-excluded** from
/// candidacy so they can never be selected — satisfying the acceptance
/// criteria — while the penalties keep scoring honest for any borderline data.
enum TodayContextEngine {

    // Scoring weights, exposed for tests and clarity.
    static let explicitMomentBonus = 100
    static let inferredMomentBonus = 60
    static let timeContextBonus = 35
    static let preferredDeityBonus = 40
    static let needsReviewPenalty = -100
    static let completedTodayPenalty = -50
    static let unavailableModePenalty = -1000

    /// Build the full Today context for the screen.
    static func makeContext(input: TodayEngineInput) -> TodayContext {
        let theme = ThemePalette.palette(for: input.timeContext)
        let resolvedMoment = input.explicitMoment ?? input.timeContext.inferredMoments.first

        let ranked = rankedPrayers(input: input)
        let selected = ranked.first
        let alternates = Array(ranked.dropFirst().prefix(3))

        return TodayContext(
            timeContext: input.timeContext,
            moment: resolvedMoment,
            theme: theme,
            headline: theme.headline,
            subheadline: theme.subheadline,
            selectedPrayer: selected,
            alternatePrayers: alternates
        )
    }

    /// All eligible prayers, ranked best-first.
    static func rankedPrayers(input: TodayEngineInput) -> [Prayer] {
        let candidates = input.prayers.filter { $0.isEligibleForToday }
        return candidates
            .map { (prayer: $0, score: score($0, input: input)) }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                // Stable tie-breaks: featured first, then sortOrder, then id.
                if lhs.prayer.isFeatured != rhs.prayer.isFeatured {
                    return lhs.prayer.isFeatured && !rhs.prayer.isFeatured
                }
                if lhs.prayer.sortOrder != rhs.prayer.sortOrder {
                    return lhs.prayer.sortOrder < rhs.prayer.sortOrder
                }
                return lhs.prayer.id < rhs.prayer.id
            }
            .map(\.prayer)
    }

    /// The score for a single prayer given the input. Pure.
    static func score(_ prayer: Prayer, input: TodayEngineInput) -> Int {
        var score = 0

        if let explicit = input.explicitMoment, prayer.moments.contains(explicit) {
            score += explicitMomentBonus
        }

        // Inferred moments: from the time band plus the user's favourites.
        var inferred = Set(input.timeContext.inferredMoments)
        inferred.formUnion(input.preferredMoments)
        // Avoid double-counting the explicit moment as inferred.
        if let explicit = input.explicitMoment {
            inferred.remove(explicit)
        }
        if inferred.contains(where: { prayer.moments.contains($0) }) {
            score += inferredMomentBonus
        }

        if prayer.timeContexts.contains(input.timeContext) {
            score += timeContextBonus
        }

        if let deity = input.preferredDeity, prayer.deity == deity {
            score += preferredDeityBonus
        }

        if prayer.needsReview {
            score += needsReviewPenalty
        }

        if input.completedPrayerIDsToday.contains(prayer.id) {
            score += completedTodayPenalty
        }

        if prayer.availableModes.isEmpty {
            score += unavailableModePenalty
        }

        return score
    }
}
