import Foundation

/// Deterministic engine that selects the single prayer to surface on Today.
///
/// Positive signals:
/// - `+100` the prayer matches an **explicitly** chosen moment
/// - `+60`  the prayer matches an **inferred** moment (from the time band or a
///          favourited moment)
/// - `+35`  the prayer's time contexts include the current band
/// - `+40`  the prayer's deity matches the user's preferred (ishta) deity
///
/// Recency penalties (a completion never *excludes* a prayer — it only nudges
/// it down so the day feels fresh, while tomorrow's repetition is allowed):
/// - `-90` completed this session (unless the user tapped Repeat)
/// - `-60` completed earlier today
/// - `-20` completed yesterday — **waived for `.dailyAnchor` prayers**
/// - `-10` completed within the last 3 days
/// - `0`   completed 4+ days ago, or never
///
/// `needsReview` / unreviewed prayers are **hard-excluded** from candidacy so
/// they can never be selected. Every eligible prayer is completable (at minimum
/// in Silent), so the absence of audio or modes never excludes it.
enum TodayContextEngine {

    // Scoring weights, exposed for tests and clarity.
    static let explicitMomentBonus = 100
    static let inferredMomentBonus = 60
    static let timeContextBonus = 35
    static let preferredDeityBonus = 40
    static let needsReviewPenalty = -100

    // Recency penalties.
    static let thisSessionPenalty = -90
    static let earlierTodayPenalty = -60
    static let yesterdayPenalty = -20
    static let withinThreeDaysPenalty = -10

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

        let recency = input.completionRecency[prayer.id] ?? .longAgoOrNever
        score += recencyPenalty(recency, policy: prayer.rotationPolicy)

        return score
    }

    /// The deprioritisation for a given recency, softened for daily anchors.
    static func recencyPenalty(_ recency: CompletionRecency, policy: RotationPolicy) -> Int {
        switch recency {
        case .thisSession:
            return thisSessionPenalty
        case .earlierToday:
            return earlierTodayPenalty
        case .yesterday:
            // Daily anchors are meant to return each day, so we don't nudge
            // them down for a completion the day before.
            return policy == .dailyAnchor ? 0 : yesterdayPenalty
        case .withinThreeDays:
            return withinThreeDaysPenalty
        case .longAgoOrNever:
            return 0
        }
    }
}
