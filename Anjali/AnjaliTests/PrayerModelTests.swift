import XCTest
@testable import Anjali

final class PrayerModelTests: XCTestCase {

    private func makePrayer(modes: [PlayMode], reviewed: Bool = true, needsReview: Bool = false) -> Prayer {
        Prayer(
            id: "p", title: "P", deity: .shiva, moments: [.sleep],
            intentions: [.peace], timeContexts: [.night], durationSeconds: 30,
            availableModes: modes, primaryText: PrayerText(devanagari: "ॐ"),
            transliteration: "Oṃ", meaning: "m", sourceTitle: "s",
            audioAssetName: nil, isReviewed: reviewed, needsReview: needsReview,
            isFeatured: false, sortOrder: 0, rotationPolicy: .rotateOften
        )
    }

    // MARK: playableModes always includes Silent

    func testPlayableModesKeepsListedModesAndSilent() {
        let p = makePrayer(modes: [.listen, .chant, .silent])
        XCTAssertEqual(p.playableModes, [.listen, .chant, .silent])
    }

    func testPlayableModesAppendsSilentWhenMissing() {
        let p = makePrayer(modes: [.listen, .chant])
        XCTAssertEqual(p.playableModes, [.listen, .chant, .silent])
        XCTAssertTrue(p.playableModes.contains(.silent))
    }

    func testPlayableModesForEmptyIsSilentOnly() {
        let p = makePrayer(modes: [])
        XCTAssertEqual(p.playableModes, [.silent])
    }

    func testSilentAlwaysAvailableForEveryModeSet() {
        // Whatever the listed modes, Silent is always playable.
        let combos: [[PlayMode]] = [[], [.listen], [.chant], [.silent], [.listen, .chant]]
        for combo in combos {
            XCTAssertTrue(makePrayer(modes: combo).playableModes.contains(.silent), "\(combo)")
        }
    }

    // MARK: Eligibility

    func testEligibilityIgnoresModesButRespectsReview() {
        XCTAssertTrue(makePrayer(modes: []).isEligibleForToday, "empty modes is still eligible")
        XCTAssertFalse(makePrayer(modes: [.silent], needsReview: true).isEligibleForToday)
        XCTAssertFalse(makePrayer(modes: [.silent], reviewed: false).isEligibleForToday)
    }

    // MARK: Duration label

    func testDurationLabel() {
        XCTAssertEqual(makePrayer(modes: [.silent]).durationLabel, "30s")
    }
}
