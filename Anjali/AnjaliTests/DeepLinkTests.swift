import XCTest
@testable import Anjali

final class DeepLinkTests: XCTestCase {

    private func link(_ string: String) -> DeepLink? {
        guard let url = URL(string: string) else { return nil }
        return DeepLink(url: url)
    }

    // MARK: Valid

    func testValidMomentLink() {
        XCTAssertEqual(link("anjali://moment/dawn"), .moment(.dawn))
        XCTAssertEqual(link("anjali://moment/sleep"), .moment(.sleep))
        XCTAssertEqual(link("anjali://moment/leavingHome"), .moment(.leavingHome))
    }

    func testValidPrayerLink() {
        XCTAssertEqual(link("anjali://prayer/ganesha-gam"), .prayer(prayerID: "ganesha-gam"))
        XCTAssertEqual(link("anjali://prayer/surya-gayatri"), .prayer(prayerID: "surya-gayatri"))
    }

    // MARK: Invalid

    func testWrongSchemeIsRejected() {
        XCTAssertNil(link("https://moment/dawn"))
        XCTAssertNil(link("http://prayer/ganesha-gam"))
    }

    func testUnknownKindIsRejected() {
        XCTAssertNil(link("anjali://something/dawn"))
        XCTAssertNil(link("anjali://deity/shiva"))
    }

    func testUnknownMomentIdIsRejected() {
        XCTAssertNil(link("anjali://moment/not-a-real-moment"))
        XCTAssertNil(link("anjali://moment/"))
    }

    func testEmptyPrayerIdIsRejected() {
        XCTAssertNil(link("anjali://prayer/"))
        XCTAssertNil(link("anjali://prayer"))
    }

    // MARK: Round-trip

    func testRoundTripMoment() {
        for moment in Moment.allCases {
            let url = DeepLink.moment(moment).url
            XCTAssertNotNil(url)
            XCTAssertEqual(DeepLink(url: url!), .moment(moment))
        }
    }

    func testRoundTripPrayer() {
        let original = DeepLink.prayer(prayerID: "krishna-mahamantra")
        let url = original.url
        XCTAssertNotNil(url)
        XCTAssertEqual(DeepLink(url: url!), original)
    }
}
