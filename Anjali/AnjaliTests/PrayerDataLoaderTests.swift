import XCTest
@testable import Anjali

final class PrayerDataLoaderTests: XCTestCase {

    func testLoadsBundledSeedPrayers() throws {
        // The seed file ships in the host app bundle. Prefer the test bundle,
        // then fall back to main; never throw if one of them is missing it.
        let loaded = (try? PrayerDataLoader.loadPrayers(bundle: Bundle(for: Self.self)))
            ?? (try? PrayerDataLoader.loadPrayers(bundle: .main))
            ?? []
        XCTAssertGreaterThanOrEqual(loaded.count, 20, "Expected the full seed set")
        XCTAssertTrue(loaded.allSatisfy { $0.isReviewed }, "Seed prayers must be reviewed")
        XCTAssertTrue(loaded.allSatisfy { !$0.needsReview }, "Seed prayers must not need review")
    }

    func testValidatesRequiredFields() {
        let good = makePrayer(id: "ok")
        XCTAssertTrue(PrayerDataLoader.isValid(good))

        XCTAssertFalse(PrayerDataLoader.isValid(makePrayer(id: " ")))
        XCTAssertFalse(PrayerDataLoader.isValid(makePrayer(id: "x", title: "")))
        XCTAssertFalse(PrayerDataLoader.isValid(makePrayer(id: "x", duration: 0)))

        // Empty availableModes is VALID — the prayer is still playable in
        // Silent via Prayer.playableModes.
        XCTAssertTrue(PrayerDataLoader.isValid(makePrayer(id: "x", modes: [])))
    }

    func testEmptyModesPrayerLoadsAndFallsBackToSilent() {
        let json = """
        [
          { "id": "noModes", "title": "No Modes", "deity": "shiva", "moments": ["sleep"],
            "intentions": ["peace"], "timeContexts": ["night"], "durationSeconds": 15,
            "availableModes": [], "primaryText": { "devanagari": "ॐ" },
            "transliteration": "Oṃ", "meaning": "Test", "sourceTitle": "Test",
            "audioAssetName": null, "isReviewed": true, "needsReview": false,
            "isFeatured": false, "sortOrder": 1, "rotationPolicy": "rotateOften" }
        ]
        """
        let prayers = PrayerDataLoader.loadPrayers(from: Data(json.utf8))
        XCTAssertEqual(prayers.count, 1)
        XCTAssertEqual(prayers.first?.playableModes, [.silent])
    }

    func testSkipsMalformedEntriesWithoutCrashing() {
        let json = """
        [
          { "id": "valid", "title": "Valid", "deity": "shiva", "moments": ["sleep"],
            "intentions": ["peace"], "timeContexts": ["night"], "durationSeconds": 15,
            "availableModes": ["silent"], "primaryText": { "devanagari": "ॐ" },
            "transliteration": "Oṃ", "meaning": "Test", "sourceTitle": "Test",
            "audioAssetName": null, "isReviewed": true, "needsReview": false,
            "isFeatured": false, "sortOrder": 1, "rotationPolicy": "rotateOften" },
          { "id": "broken", "title": 12345 },
          "not even an object"
        ]
        """
        let data = Data(json.utf8)
        let prayers = PrayerDataLoader.loadPrayers(from: data)
        XCTAssertEqual(prayers.count, 1)
        XCTAssertEqual(prayers.first?.id, "valid")
    }

    func testEmptyDataReturnsEmptyArray() {
        XCTAssertEqual(PrayerDataLoader.loadPrayers(from: Data("garbage".utf8)).count, 0)
    }

    // MARK: Helpers

    private func makePrayer(
        id: String,
        title: String = "Title",
        duration: Int = 15,
        modes: [PlayMode] = [.silent]
    ) -> Prayer {
        Prayer(
            id: id, title: title, deity: .shiva, moments: [.sleep],
            intentions: [.peace], timeContexts: [.night], durationSeconds: duration,
            availableModes: modes, primaryText: PrayerText(devanagari: "ॐ"),
            transliteration: "Oṃ", meaning: "meaning", sourceTitle: "source",
            audioAssetName: nil, isReviewed: true, needsReview: false,
            isFeatured: false, sortOrder: 0, rotationPolicy: .rotateOften
        )
    }
}
