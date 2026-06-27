import Foundation

/// Maps a wall-clock time to a `TimeContext` band.
///
/// Band boundaries (local time):
/// - Dawn:    04:30 – 08:00
/// - Morning: 08:00 – 16:30  (extends through midday so the day is fully covered)
/// - Sunset:  16:30 – 20:00
/// - Night:   20:00 – 04:30  (wraps past midnight)
///
/// The spec defines Dawn/Morning/Sunset/Night anchors; midday (12:00–16:30)
/// is folded into the Morning theme so there is never an undefined gap.
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
        let sunsetStart = 16 * 60 + 30   // 16:30
        let nightStart = 20 * 60         // 20:00

        switch minutes {
        case dawnStart..<morningStart:
            return .dawn
        case morningStart..<sunsetStart:
            return .morning
        case sunsetStart..<nightStart:
            return .sunset
        default:
            // Covers 20:00–23:59 and 00:00–04:29.
            return .night
        }
    }
}
