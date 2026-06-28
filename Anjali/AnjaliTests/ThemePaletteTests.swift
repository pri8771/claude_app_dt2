import XCTest
@testable import Anjali

final class ThemePaletteTests: XCTestCase {

    private let allBands = TimeContext.allCases  // dawn, morning, midday, sunset, night

    func testEveryBandHasCopyAndGradient() {
        for band in allBands {
            let p = ThemePalette.palette(for: band)
            XCTAssertFalse(p.eyebrow.isEmpty, "\(band) eyebrow")
            XCTAssertFalse(p.headline.isEmpty, "\(band) headline")
            XCTAssertFalse(p.subheadline.isEmpty, "\(band) subheadline")
            XCTAssertGreaterThanOrEqual(p.gradient.count, 2, "\(band) needs a multi-stop gradient")
        }
    }

    func testEachBandPaletteIsDistinct() {
        let palettes = allBands.map { ThemePalette.palette(for: $0) }
        for i in palettes.indices {
            for j in palettes.indices where j > i {
                XCTAssertNotEqual(
                    palettes[i], palettes[j],
                    "\(allBands[i]) and \(allBands[j]) palettes must differ"
                )
            }
        }
    }

    func testMiddayIsDistinctFromMorning() {
        // They share an accent family but must not be identical (different copy
        // and a more saturated midday gradient).
        XCTAssertNotEqual(
            ThemePalette.palette(for: .midday),
            ThemePalette.palette(for: .morning)
        )
    }

    func testForegroundPolarityMatchesBand() {
        // Light bands want dark text; dark bands want light text.
        XCTAssertTrue(ThemePalette.palette(for: .morning).prefersDarkForeground)
        XCTAssertTrue(ThemePalette.palette(for: .midday).prefersDarkForeground)
        XCTAssertFalse(ThemePalette.palette(for: .dawn).prefersDarkForeground)
        XCTAssertFalse(ThemePalette.palette(for: .sunset).prefersDarkForeground)
        XCTAssertFalse(ThemePalette.palette(for: .night).prefersDarkForeground)
    }
}
