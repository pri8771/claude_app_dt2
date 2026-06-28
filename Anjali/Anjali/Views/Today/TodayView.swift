import SwiftUI
import SwiftData

/// The Today screen: a single contextual prayer card over a time-band theme.
struct TodayView: View {
    @EnvironmentObject private var library: PrayerLibrary
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var coordinator: AppCoordinator

    @Query private var completions: [PrayerCompletion]
    @Environment(\.scenePhase) private var scenePhase

    /// Recomputed on appearance; the band only needs to be resolved when the
    /// screen is shown.
    @State private var now = Date()
    /// Which of today's contextual prayers the card is showing (0 = the
    /// top-ranked selection; "Change" steps through the rest).
    @State private var cardIndex = 0
    /// Dynamic Type multiplier for the display headline.
    @ScaledMetric(relativeTo: .largeTitle) private var typeScale: CGFloat = 1

    private var context: TodayContext {
        let calendar = Calendar.current
        let input = TodayEngineInput(
            prayers: library.prayers,
            timeContext: TimeBandResolver.timeContext(for: now, calendar: calendar),
            explicitMoment: nil,
            preferredDeity: settings.ishtaDevata,
            preferredMoments: settings.favoriteMoments,
            preferredMode: settings.preferredPrayerMode,
            completionRecency: buildRecency(now: now, calendar: calendar)
        )
        return TodayContextEngine.makeContext(input: input)
    }

    /// Bucket each prayer's most recent completion into a `CompletionRecency`.
    /// Prayers completed during this session are marked `.thisSession`.
    private func buildRecency(now: Date, calendar: Calendar) -> [String: CompletionRecency] {
        var latest: [String: Date] = [:]
        for completion in completions {
            if let existing = latest[completion.prayerID] {
                if completion.completedAt > existing { latest[completion.prayerID] = completion.completedAt }
            } else {
                latest[completion.prayerID] = completion.completedAt
            }
        }

        let today = calendar.startOfDay(for: now)
        var result: [String: CompletionRecency] = [:]
        for (id, date) in latest {
            let completedDay = calendar.startOfDay(for: date)
            let days = calendar.dateComponents([.day], from: completedDay, to: today).day ?? 0
            switch days {
            case ..<1:        result[id] = .earlierToday   // today (or clock skew)
            case 1:           result[id] = .yesterday
            case 2, 3:        result[id] = .withinThreeDays
            default:          result[id] = .longAgoOrNever
            }
        }
        // Session completions are the strongest, most recent signal.
        for id in coordinator.sessionCompletedPrayerIDs {
            result[id] = .thisSession
        }
        return result
    }

    /// Today's contextual prayers in ranked order (selection first).
    private func todayPrayers(_ context: TodayContext) -> [Prayer] {
        guard let selected = context.selectedPrayer else { return [] }
        return [selected] + context.alternatePrayers
    }

    var body: some View {
        let context = context
        let theme = context.theme
        let prayers = todayPrayers(context)
        let displayed = prayers.isEmpty ? nil : prayers[min(cardIndex, prayers.count - 1)]

        ZStack {
            TimeBandBackground(timeContext: context.timeContext)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header(theme: theme, context: context)

                    if let prayer = displayed {
                        PrayerCardView(
                            prayer: prayer,
                            theme: theme,
                            canChange: prayers.count > 1,
                            onBegin: { coordinator.play(prayer) },
                            onSilent: { coordinator.play(prayer, forcedMode: .silent) },
                            onChange: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    cardIndex = (cardIndex + 1) % prayers.count
                                }
                            }
                        )
                        .id(prayer.id)
                        .transition(.opacity)
                    } else {
                        emptyState(theme: theme)
                    }
                }
                .padding(20)
            }
        }
        .preferredColorScheme(theme.prefersDarkForeground ? .light : .dark)
        .onAppear {
            now = Date()
            cardIndex = 0
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                withAnimation(.easeInOut(duration: 0.8)) { now = Date() }
            }
        }
    }

    private func header(theme: ThemePalette, context: TodayContext) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(theme.eyebrow.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundStyle(theme.accent)
            Text(context.headline)
                .font(.system(size: 30 * typeScale, weight: .semibold, design: .serif))
                .foregroundStyle(theme.foreground)
                .minimumScaleFactor(0.7)
            Text(context.subheadline)
                .font(.body)
                .foregroundStyle(theme.secondaryForeground)
        }
        .padding(.top, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(theme.eyebrow). \(context.headline). \(context.subheadline)")
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
