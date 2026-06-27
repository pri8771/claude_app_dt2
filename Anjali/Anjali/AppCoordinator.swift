import Foundation
import SwiftUI

/// The three primary tabs.
enum AppTab: Hashable {
    case today
    case moments
    case me
}

/// App-wide navigation state. Routes deep links, owns the currently selected
/// tab, and drives full-screen presentation of the prayer player so cards,
/// lists, and notifications all funnel through one place.
@MainActor
final class AppCoordinator: ObservableObject {
    @Published var selectedTab: AppTab = .today
    /// The prayer currently presented in the full-screen player, if any.
    @Published var activePrayer: Prayer?
    /// A moment the user navigated into from a deep link / browse.
    @Published var pendingMoment: Moment?

    private unowned let library: PrayerLibrary

    init(library: PrayerLibrary) {
        self.library = library
    }

    /// Present the player for a prayer.
    func play(_ prayer: Prayer) {
        activePrayer = prayer
    }

    func dismissPlayer() {
        activePrayer = nil
    }

    /// Handle a parsed deep link.
    func handle(_ link: DeepLink) {
        switch link {
        case .prayer(let id):
            if let prayer = library.prayer(withID: id) {
                selectedTab = .today
                play(prayer)
            }
        case .moment(let moment):
            selectedTab = .moments
            pendingMoment = moment
        }
    }

    /// Handle an incoming URL (from `onOpenURL`).
    func handle(url: URL) {
        guard let link = DeepLink(url: url) else { return }
        handle(link)
    }

    /// Handle a notification whose userInfo carries a deep link.
    func handleNotificationUserInfo(_ userInfo: [AnyHashable: Any]) {
        guard let urlString = userInfo["deepLink"] as? String,
              let url = URL(string: urlString),
              let link = DeepLink(url: url) else { return }
        handle(link)
    }
}
