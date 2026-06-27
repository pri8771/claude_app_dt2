import Foundation
import UserNotifications

/// The three daily reminders, with stable identifiers so re-scheduling
/// replaces rather than duplicates.
enum ReminderSlot: String, CaseIterable, Identifiable {
    case dawn = "reminder.dawn"
    case sunset = "reminder.sunset"
    case sleep = "reminder.sleep"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dawn: return "Begin with light"
        case .sunset: return "Return with gratitude"
        case .sleep: return "Rest in peace"
        }
    }

    var body: String {
        switch self {
        case .dawn: return "A sacred pause to start the day."
        case .sunset: return "A moment to give thanks."
        case .sleep: return "Let the day settle before sleep."
        }
    }

    /// Default trigger time (local) for this reminder.
    var defaultHour: Int {
        switch self {
        case .dawn: return 6
        case .sunset: return 18
        case .sleep: return 21
        }
    }

    var defaultMinute: Int { 30 }

    /// The moment a tap should deep-link into.
    var deepLink: DeepLink {
        switch self {
        case .dawn: return .moment(.dawn)
        case .sunset: return .moment(.sunset)
        case .sleep: return .moment(.sleep)
        }
    }
}

/// Thin wrapper over `UNUserNotificationCenter` for local-only daily reminders.
@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// Ask permission. Returns whether the user granted alerts.
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Schedule a single daily reminder at its default time. Uses the slot's
    /// stable identifier so repeated calls replace the existing request.
    func schedule(_ slot: ReminderSlot) {
        let content = UNMutableNotificationContent()
        content.title = slot.title
        content.body = slot.body
        content.sound = .default
        if let urlString = slot.deepLink.url?.absoluteString {
            content.userInfo = ["deepLink": urlString]
        }

        var components = DateComponents()
        components.hour = slot.defaultHour
        components.minute = slot.defaultMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: slot.rawValue,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancel(_ slot: ReminderSlot) {
        center.removePendingNotificationRequests(withIdentifiers: [slot.rawValue])
    }

    /// Reconcile scheduled reminders with the set the user has enabled.
    func sync(enabledSlots: Set<ReminderSlot>) {
        for slot in ReminderSlot.allCases {
            if enabledSlots.contains(slot) {
                schedule(slot)
            } else {
                cancel(slot)
            }
        }
    }
}
