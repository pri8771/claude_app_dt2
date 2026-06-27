import XCTest
@testable import Anjali

final class TimeBandResolverTests: XCTestCase {

    private func minutes(_ hour: Int, _ minute: Int) -> Int { hour * 60 + minute }

    func testDawnBoundaries() {
        XCTAssertEqual(TimeBandResolver.timeContext(forMinutesSinceMidnight: minutes(4, 30)), .dawn)
        XCTAssertEqual(TimeBandResolver.timeContext(forMinutesSinceMidnight: minutes(6, 0)), .dawn)
        XCTAssertEqual(TimeBandResolver.timeContext(forMinutesSinceMidnight: minutes(7, 59)), .dawn)
    }

    func testMorningBoundaries() {
        XCTAssertEqual(TimeBandResolver.timeContext(forMinutesSinceMidnight: minutes(8, 0)), .morning)
        XCTAssertEqual(TimeBandResolver.timeContext(forMinutesSinceMidnight: minutes(11, 59)), .morning)
        // Midday folds into morning so there is no gap.
        XCTAssertEqual(TimeBandResolver.timeContext(forMinutesSinceMidnight: minutes(14, 0)), .morning)
        XCTAssertEqual(TimeBandResolver.timeContext(forMinutesSinceMidnight: minutes(16, 29)), .morning)
    }

    func testSunsetBoundaries() {
        XCTAssertEqual(TimeBandResolver.timeContext(forMinutesSinceMidnight: minutes(16, 30)), .sunset)
        XCTAssertEqual(TimeBandResolver.timeContext(forMinutesSinceMidnight: minutes(18, 0)), .sunset)
        XCTAssertEqual(TimeBandResolver.timeContext(forMinutesSinceMidnight: minutes(19, 59)), .sunset)
    }

    func testNightBoundariesAndWrap() {
        XCTAssertEqual(TimeBandResolver.timeContext(forMinutesSinceMidnight: minutes(20, 0)), .night)
        XCTAssertEqual(TimeBandResolver.timeContext(forMinutesSinceMidnight: minutes(23, 59)), .night)
        XCTAssertEqual(TimeBandResolver.timeContext(forMinutesSinceMidnight: minutes(0, 0)), .night)
        XCTAssertEqual(TimeBandResolver.timeContext(forMinutesSinceMidnight: minutes(4, 29)), .night)
    }

    func testResolvesFromDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        var comps = DateComponents()
        comps.year = 2026; comps.month = 6; comps.day = 27
        comps.hour = 6; comps.minute = 0
        let date = calendar.date(from: comps)!
        XCTAssertEqual(TimeBandResolver.timeContext(for: date, calendar: calendar), .dawn)
    }
}
