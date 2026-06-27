import Foundation

/// The fully resolved context for the Today screen: which band we are in, the
/// inferred or chosen moment, the theme/copy, and the chosen prayer plus a few
/// alternates. Produced by `TodayContextEngine`.
struct TodayContext {
    let timeContext: TimeContext
    let moment: Moment?
    let theme: ThemePalette
    let headline: String
    let subheadline: String
    let selectedPrayer: Prayer?
    let alternatePrayers: [Prayer]
}

/// How recently a prayer was last completed, bucketed for scoring. Completion
/// never *excludes* a prayer — it only deprioritises it, and daily anchors are
/// exempt from the gentle "yesterday" nudge so they can return each day.
enum CompletionRecency: Hashable {
    /// Completed during the current app session (just now). The strongest
    /// nudge, so the card moves on after you finish — unless you tapped Repeat.
    case thisSession
    /// Completed earlier today.
    case earlierToday
    /// Completed yesterday.
    case yesterday
    /// Completed 2–3 days ago.
    case withinThreeDays
    /// Completed 4+ days ago, or never.
    case longAgoOrNever
}

/// The inputs the engine needs to deterministically pick a prayer. Everything
/// is passed in explicitly (no clocks, no globals) so the engine is pure.
struct TodayEngineInput {
    var prayers: [Prayer]
    var timeContext: TimeContext
    /// A moment the user has explicitly selected (e.g. via a deep link or the
    /// Moments tab). When set it dominates scoring.
    var explicitMoment: Moment?
    /// The user's chosen ishta devata, if any.
    var preferredDeity: Deity?
    /// Moments the user has favourited.
    var preferredMoments: [Moment]
    /// Most recent completion recency per prayer id. Absent ids are treated as
    /// `.longAgoOrNever`.
    var completionRecency: [String: CompletionRecency]

    init(
        prayers: [Prayer],
        timeContext: TimeContext,
        explicitMoment: Moment? = nil,
        preferredDeity: Deity? = nil,
        preferredMoments: [Moment] = [],
        completionRecency: [String: CompletionRecency] = [:]
    ) {
        self.prayers = prayers
        self.timeContext = timeContext
        self.explicitMoment = explicitMoment
        self.preferredDeity = preferredDeity
        self.preferredMoments = preferredMoments
        self.completionRecency = completionRecency
    }
}
