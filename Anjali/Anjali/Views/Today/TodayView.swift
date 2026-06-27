import SwiftUI
import SwiftData

/// The Today screen: a single contextual prayer card over a time-band theme.
struct TodayView: View {
    @EnvironmentObject private var library: PrayerLibrary
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var coordinator: AppCoordinator

    @Query private var completions: [PrayerCompletion]

    /// Recomputed on appearance; the band only needs to be resolved when the
    /// screen is shown.
    @State private var now = Date()

    private var context: TodayContext {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let completedToday = Set(
            completions
                .filter { $0.completedAt >= startOfDay }
                .map(\.prayerID)
        )

        let input = TodayEngineInput(
            prayers: library.prayers,
            timeContext: TimeBandResolver.timeContext(for: now, calendar: calendar),
            explicitMoment: nil,
            preferredDeity: settings.ishtaDevata,
            preferredMoments: settings.favoriteMoments,
            completedPrayerIDsToday: completedToday
        )
        return TodayContextEngine.makeContext(input: input)
    }

    var body: some View {
        let context = context
        let theme = context.theme

        ZStack {
            theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header(theme: theme, context: context)

                    if let prayer = context.selectedPrayer {
                        PrayerCardView(prayer: prayer, theme: theme) {
                            coordinator.play(prayer)
                        }
                    } else {
                        emptyState(theme: theme)
                    }
                }
                .padding(20)
            }
        }
        .preferredColorScheme(theme.prefersDarkForeground ? .light : .dark)
        .onAppear { now = Date() }
    }

    private func header(theme: ThemePalette, context: TodayContext) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(theme.eyebrow.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundStyle(theme.accent)
            Text(context.headline)
                .font(.system(size: 30, weight: .semibold, design: .serif))
                .foregroundStyle(theme.foreground)
            Text(context.subheadline)
                .font(.body)
                .foregroundStyle(theme.secondaryForeground)
        }
        .padding(.top, 24)
    }

    private func emptyState(theme: ThemePalette) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "flame")
                .font(.largeTitle)
                .foregroundStyle(theme.accent)
            Text(library.loadError ?? "No prayer is ready right now.")
                .font(.headline)
                .foregroundStyle(theme.foreground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
