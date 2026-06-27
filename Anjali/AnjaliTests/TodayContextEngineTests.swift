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
        sortOrder: Int = 0
    ) -> Prayer {
        Prayer(
            id: id, title: id, deity: deity, moments: moments,
            intentions: [], timeContexts: timeContexts, durationSeconds: 15,
            availableModes: modes, primaryText: PrayerText(devanagari: "ॐ"),
            transliteration: "Oṃ", meaning: "m", sourceTitle: "s",
            audioAssetName: nil, isReviewed: isReviewed, needsReview: needsReview,
            isFeatured: featured, sortOrder: sortOrder
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

    // MARK: Preferred deity ranking

    func testPreferredDeityIsRankedHigher() {
        // Two prayers identical except deity; both match the time band.
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

    // MARK: Recently-completed deprioritisation

    func testRecentlyCompletedIsDeprioritised() {
        let a = prayer("a", moments: [.dawn], timeContexts: [.dawn], sortOrder: 0)
        let b = prayer("b", moments: [.dawn], timeContexts: [.dawn], sortOrder: 1)
        // Without completions, "a" wins on sortOrder tie-break.
        let baseline = TodayContextEngine.makeContext(
            input: TodayEngineInput(prayers: [a, b], timeContext: .dawn)
        )
        XCTAssertEqual(baseline.selectedPrayer?.id, "a")

        // Marking "a" completed today should push "b" ahead.
        let input = TodayEngineInput(
            prayers: [a, b],
            timeContext: .dawn,
            completedPrayerIDsToday: ["a"]
        )
        let context = TodayContextEngine.makeContext(input: input)
        XCTAssertEqual(context.selectedPrayer?.id, "b")
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

    func testPrayerWithNoModesIsExcluded() {
        let noModes = prayer("none", moments: [.dawn], timeContexts: [.dawn], modes: [])
        let good = prayer("g", moments: [.dawn], timeContexts: [.dawn])
        let context = TodayContextEngine.makeContext(
            input: TodayEngineInput(prayers: [noModes, good], timeContext: .dawn)
        )
        XCTAssertEqual(context.selectedPrayer?.id, "g")
    }

    // MARK: Explicit moment override

    func testExplicitMomentOverridesTimeBand() {
        // It's morning, but the user explicitly chose Travel.
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

    // MARK: Scoring weights

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

    func testEmptyLibraryYieldsNoSelection() {
        let context = TodayContextEngine.makeContext(
            input: TodayEngineInput(prayers: [], timeContext: .dawn)
        )
        XCTAssertNil(context.selectedPrayer)
        XCTAssertTrue(context.alternatePrayers.isEmpty)
        // Theme/copy is still well-formed.
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
