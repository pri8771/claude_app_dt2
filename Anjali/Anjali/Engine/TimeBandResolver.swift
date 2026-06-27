import Foundation

/// Maps a wall-clock time to a `TimeContext` band.
///
/// Band boundaries (local time):
/// - Dawn:    04:30 – 07:59
/// - Morning: 08:00 – 11:59
/// - Midday:  12:00 – 15:59
/// - Sunset:  16:00 – 19:59
/// - Night:   20:00 – 04:29  (wraps past midnight)
///
/// Every minute of the day maps to exactly one band — there is no gap.
enum TimeBandResolver {

    /// Resolve a band from a concrete date using the given calendar.
    static func timeContext(for date: Date, calendar: Calendar = .current) -> TimeContext {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        return timeContext(forMinutesSinceMidnight: minutes)
    }

    /// Resolve a band from minutes since local midnight. Pure and easily tested.
    static func timeContext(forMinutesSinceMidnight minutes: Int) -> TimeContext {
        let dawnStart = 4 * 60 + 30      // 04:30
        let morningStart = 8 * 60        // 08:00
        let middayStart = 12 * 60        // 12:00
        let sunsetStart = 16 * 60        // 16:00
        let nightStart = 20 * 60         // 20:00

        switch minutes {
        case dawnStart..<morningStart:
            return .dawn
        case morningStart..<middayStart:
            return .morning
        case middayStart..<sunsetStart:
            return .midday
        case sunsetStart..<nightStart:
            return .sunset
        default:
            // Covers 20:00–23:59 and 00:00–04:29.
            return .night
        }
    }
}
