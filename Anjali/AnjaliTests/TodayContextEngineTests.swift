import XCTest
@testable import Anjali

final class TodayContextEngineTests: XCTestCase {

    // MARK: Fixtures

    private func prayer(
        _ id: String,
        deity: Deity? = .shiva,
        moments: [Moment] = [],
        timeContexts: [TimeContext] = [],
        modes: [PlayMode] = [.silent],
        needsReview: Bool = false,
        isReviewed: Bool = true,
        featured: Bool = false,
        sortOrder: Int = 0,
        rotationPolicy: RotationPolicy = .rotateOften
    ) -> Prayer {
        Prayer(
            id: id, title: id, deity: deity, moments: moments,
            intentions: [], timeContexts: timeContexts, durationSeconds: 15,
            availableModes: modes, primaryText: PrayerText(devanagari: "ॐ"),
            transliteration: "Oṃ", meaning: "m", sourceTitle: "s",
            audioAssetName: nil, isReviewed: isReviewed, needsReview: needsReview,
            isFeatured: featured, sortOrder: sortOrder, rotationPolicy: rotationPolicy
        )
    }

    // MARK: Time-band selection

    func testDawnSelectsDawnPrayer() {
        let dawnPrayer = prayer("dawn", moments: [.dawn], timeContexts: [.dawn])
        let nightPrayer = prayer("night", moments: [.sleep], timeContexts: [.night])
        let input = TodayEngineInput(prayers: [dawnPrayer, nightPrayer], timeContext: .dawn)
        let context = TodayContextEngine.makeContext(input: input)
        XCTAssertEqual(context.selectedPrayer?.id, "dawn")
        XCTAssertEqual(context.timeContext, .dawn)
    }

    func testSunsetSelectsSunsetPrayer() {
        let sunsetPrayer = prayer("sunset", moments: [.sunset], timeContexts: [.sunset])
        let dawnPrayer = prayer("dawn", moments: [.dawn], timeContexts: [.dawn])
        let input = TodayEngineInput(prayers: [dawnPrayer, sunsetPrayer], timeContext: .sunset)
        let context = TodayContextEngine.makeContext(input: input)
        XCTAssertEqual(context.selectedPrayer?.id, "sunset")
    }

    func testNightSelectsNightPrayer() {
        let sleepPrayer = prayer("sleep", moments: [.sleep], timeContexts: [.night])
        let morningPrayer = prayer("morning", moments: [.beforeWork], timeContexts: [.morning])
        let input = TodayEngineInput(prayers: [morningPrayer, sleepPrayer], timeContext: .night)
        let context = TodayContextEngine.makeContext(input: input)
        XCTAssertEqual(context.selectedPrayer?.id, "sleep")
    }

    func testMiddaySelectsMiddayPrayer() {
        let middayPrayer = prayer("midday", moments: [.meeting], timeContexts: [.midday])
        let dawnPrayer = prayer("dawn", moments: [.dawn], timeContexts: [.dawn])
        let input = TodayEngineInput(prayers: [dawnPrayer, middayPrayer], timeContext: .midday)
        let context = TodayContextEngine.makeContext(input: input)
        XCTAssertEqual(context.selectedPrayer?.id, "midday")
        XCTAssertEqual(context.timeContext, .midday)
    }

    // MARK: Preferred deity ranking

    func testPreferredDeityIsRankedHigher() {
        let shivaP = prayer("shiva", deity: .shiva, timeContexts: [.morning])
        let ganeshaP = prayer("ganesha", deity: .ganesha, timeContexts: [.morning])
        let input = TodayEngineInput(
            prayers: [shivaP, ganeshaP],
            timeContext: .morning,
            preferredDeity: .ganesha
        )
        let context = TodayContextEngine.makeContext(input: input)
        XCTAssertEqual(context.selectedPrayer?.id, "ganesha")
    }

    // MARK: Recency penalties

    func testRecencyPenaltyValuesForNormalRotation() {
        let policy = RotationPolicy.rotateOften
        XCTAssertEqual(TodayContextEngine.recencyPenalty(.thisSession, policy: policy), -90)
        XCTAssertEqual(TodayContextEngine.recencyPenalty(.earlierToday, policy: policy), -60)
        XCTAssertEqual(TodayContextEngine.recencyPenalty(.yesterday, policy: policy), -20)
        XCTAssertEqual(TodayContextEngine.recencyPenalty(.withinThreeDays, policy: policy), -10)
        XCTAssertEqual(TodayContextEngine.recencyPenalty(.longAgoOrNever, policy: policy), 0)
    }

    func testEarlierTodayIsDeprioritised() {
        let a = prayer("a", moments: [.dawn], timeContexts: [.dawn], sortOrder: 0)
        let b = prayer("b", moments: [.dawn], timeContexts: [.dawn], sortOrder: 1)
        // Without recency, "a" wins on sortOrder tie-break.
        let baseline = TodayContextEngine.makeContext(
            input: TodayEngineInput(prayers: [a, b], timeContext: .dawn)
        )
        XCTAssertEqual(baseline.selectedPrayer?.id, "a")

        // Completing "a" earlier today should push "b" ahead.
        let input = TodayEngineInput(
            prayers: [a, b],
            timeContext: .dawn,
            completionRecency: ["a": .earlierToday]
        )
        let context = TodayContextEngine.makeContext(input: input)
        XCTAssertEqual(context.selectedPrayer?.id, "b")
    }

    func testThisSessionIsStrongerThanEarlierToday() {
        let a = prayer("a", moments: [.dawn], timeContexts: [.dawn], sortOrder: 0)
        let b = prayer("b", moments: [.dawn], timeContexts: [.dawn], sortOrder: 1)
        // "a" completed this session (-90) should fall below "b" completed
        // merely earlier today (-60).
        let input = TodayEngineInput(
            prayers: [a, b],
            timeContext: .dawn,
            completionRecency: ["a": .thisSession, "b": .earlierToday]
        )
        let context = TodayContextEngine.makeContext(input: input)
        XCTAssertEqual(context.selectedPrayer?.id, "b")
    }

    func testCompletionNeverExcludes() {
        // Even completed this session, a sole prayer is still selectable.
        let only = prayer("only", moments: [.dawn], timeContexts: [.dawn])
        let input = TodayEngineInput(
            prayers: [only],
            timeContext: .dawn,
            completionRecency: ["only": .thisSession]
        )
        XCTAssertEqual(TodayContextEngine.makeContext(input: input).selectedPrayer?.id, "only")
    }

    // MARK: Rotation policy

    func testDailyAnchorWaivesYesterdayPenalty() {
        XCTAssertEqual(TodayContextEngine.recencyPenalty(.yesterday, policy: .dailyAnchor), 0)
        XCTAssertEqual(TodayContextEngine.recencyPenalty(.yesterday, policy: .rotateOften), -20)
    }

    func testDailyAnchorReturnsAfterYesterdayDespiteWorseTieBreak() {
        // anchor has a *worse* sortOrder, so if it still wins it's because its
        // yesterday penalty was waived while the normal prayer's was not.
        let anchor = prayer(
            "anchor", moments: [.dawn], timeContexts: [.dawn],
            sortOrder: 5, rotationPolicy: .dailyAnchor
        )
        let normal = prayer(
            "normal", moments: [.dawn], timeContexts: [.dawn],
            sortOrder: 0, rotationPolicy: .rotateOften
        )
        let input = TodayEngineInput(
            prayers: [anchor, normal],
            timeContext: .dawn,
            completionRecency: ["anchor": .yesterday, "normal": .yesterday]
        )
        let context = TodayContextEngine.makeContext(input: input)
        XCTAssertEqual(context.selectedPrayer?.id, "anchor")
    }

    func testDailyAnchorStillPenalisedSameDay() {
        // The waiver is only for "yesterday" — same-day completions still apply.
        XCTAssertEqual(TodayContextEngine.recencyPenalty(.earlierToday, policy: .dailyAnchor), -60)
        XCTAssertEqual(TodayContextEngine.recencyPenalty(.thisSession, policy: .dailyAnchor), -90)
    }

    // MARK: needsReview exclusion

    func testNeedsReviewPrayersAreExcluded() {
        let bad = prayer("bad", moments: [.dawn], timeContexts: [.dawn], needsReview: true)
        let input = TodayEngineInput(prayers: [bad], timeContext: .dawn)
        let context = TodayContextEngine.makeContext(input: input)
        XCTAssertNil(context.selectedPrayer, "needsReview prayers must never be selected")
    }

    func testUnreviewedPrayersAreExcluded() {
        let unreviewed = prayer("u", moments: [.dawn], timeContexts: [.dawn], isReviewed: false)
        let good = prayer("g", moments: [.dawn], timeContexts: [.dawn])
        let input = TodayEngineInput(prayers: [unreviewed, good], timeContext: .dawn)
        let ranked = TodayContextEngine.rankedPrayers(input: input)
        XCTAssertEqual(ranked.map(\.id), ["g"])
    }

    // MARK: Mode fallback (Fix 4) — never blocks a text-only prayer

    func testPrayerWithNoModesIsStillSelectableInSilent() {
        let noModes = prayer("none", moments: [.dawn], timeContexts: [.dawn], modes: [])
        let context = TodayContextEngine.makeContext(
            input: TodayEngineInput(prayers: [noModes], timeContext: .dawn)
        )
        XCTAssertEqual(context.selectedPrayer?.id, "none")
        XCTAssertEqual(context.selectedPrayer?.playableModes, [.silent])
    }

    // MARK: Explicit moment override

    func testExplicitMomentOverridesTimeBand() {
        let travel = prayer("travel", moments: [.travel], timeContexts: [.dawn])
        let morning = prayer("morning", moments: [.beforeWork], timeContexts: [.morning])
        let input = TodayEngineInput(
            prayers: [travel, morning],
            timeContext: .morning,
            explicitMoment: .travel
        )
        let context = TodayContextEngine.makeContext(input: input)
        XCTAssertEqual(context.selectedPrayer?.id, "travel")
        XCTAssertEqual(context.moment, .travel)
    }

    func testExplicitMomentScoresHigherThanInferred() {
        let explicit = prayer("e", moments: [.travel])
        let inferred = prayer("i", moments: [.dawn]) // dawn is inferred for the dawn band
        let input = TodayEngineInput(
            prayers: [explicit, inferred],
            timeContext: .dawn,
            explicitMoment: .travel
        )
        XCTAssertGreaterThan(
            TodayContextEngine.score(explicit, input: input),
            TodayContextEngine.score(inferred, input: input)
        )
    }

    // MARK: Misc

    func testEmptyLibraryYieldsNoSelection() {
        let context = TodayContextEngine.makeContext(
            input: TodayEngineInput(prayers: [], timeContext: .dawn)
        )
        XCTAssertNil(context.selectedPrayer)
        XCTAssertTrue(context.alternatePrayers.isEmpty)
        XCTAssertFalse(context.headline.isEmpty)
    }

    func testAlternatesExcludeSelected() {
        let a = prayer("a", moments: [.dawn], timeContexts: [.dawn], sortOrder: 0)
        let b = prayer("b", moments: [.dawn], timeContexts: [.dawn], sortOrder: 1)
        let c = prayer("c", moments: [.dawn], timeContexts: [.dawn], sortOrder: 2)
        let context = TodayContextEngine.makeContext(
            input: TodayEngineInput(prayers: [a, b, c], timeContext: .dawn)
        )
        XCTAssertEqual(context.selectedPrayer?.id, "a")
        XCTAssertEqual(context.alternatePrayers.map(\.id), ["b", "c"])
    }
}
