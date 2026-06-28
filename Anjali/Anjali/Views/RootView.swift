import SwiftUI

/// Decides between onboarding (first launch) and the main tab experience, and
/// hosts the full-screen prayer player presented by the coordinator.
struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        Group {
            if settings.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .fullScreenCover(item: $coordinator.activePrayer) { prayer in
            PrayerPlayerView(prayer: prayer, forcedMode: coordinator.forcedMode)
        }
    }
}
