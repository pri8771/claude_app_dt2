import SwiftUI

/// Two-screen first-launch onboarding (no third step):
///  1. Wordmark + tagline.
///  2. Gentle preferences — script, preferred mode, ishta devata, optional
///     favourite moments, and an optional reminder opt-in.
struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    // Local draft of preferences, committed on finish.
    @State private var script: ScriptPreference = .both
    @State private var mode: PlayMode = .listen
    @State private var ishta: Deity?
    @State private var favoriteMoments: Set<Moment> = []
    @State private var remindersOn = false
    @State private var showReminderDeniedNote = false

    private let theme = ThemePalette.palette(for: .dawn)

    /// A small, curated subset of moments offered during onboarding.
    private struct OnboardingMoment: Identifiable {
        let moment: Moment
        let label: String
        var id: String { moment.rawValue }
    }
    private let curatedMoments: [OnboardingMoment] = [
        .init(moment: .beforeWork, label: "Morning"),
        .init(moment: .leavingHome, label: "Leaving home"),
        .init(moment: .study, label: "Work / study"),
        .init(moment: .sunset, label: "Sunset"),
        .init(moment: .sleep, label: "Sleep")
    ]

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            TabView(selection: $page) {
                welcome.tag(0)
                preferences.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .preferredColorScheme(.dark)
        .alert("Reminders are off", isPresented: $showReminderDeniedNote) {
            Button("Continue") { complete() }
        } message: {
            Text("You can always enable reminders later in Me.")
        }
    }

    // MARK: Screen 1

    private var welcome: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Anjali")
                .font(.system(.largeTitle, design: .serif, weight: .light))
                .foregroundStyle(theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("A sacred pause for everyday life")
                .font(.title3)
                .foregroundStyle(theme.foreground.opacity(0.85))
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                if reduceMotion { page = 1 } else { withAnimation { page = 1 } }
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AnjaliPrimaryButtonStyle(theme: theme))
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
    }

    // MARK: Screen 2

    private var preferences: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("A few quiet choices")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(theme.foreground)
                    Text("You can change these anytime in Me.")
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryForeground)
                }

                scriptSection
                modeSection
                ishtaSection
                momentsSection      // optional, visually secondary
                reminderSection     // optional, default off

                Button {
                    finish()
                } label: {
                    Text("Enter")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AnjaliPrimaryButtonStyle(theme: theme))
                .padding(.top, 4)
                .padding(.bottom, 56)
            }
            .padding(.horizontal, 32)
            .padding(.top, 56)
        }
    }

    private var scriptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Script")
            Picker("Script", selection: $script) {
                ForEach(ScriptPreference.allCases) { pref in
                    Text(pref.displayName).tag(pref)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("How would you like to pray?")
            Picker("Mode", selection: $mode) {
                ForEach(PlayMode.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var ishtaSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Ishta devata")
            Text("A deity close to your heart, if you have one.")
                .font(.caption)
                .foregroundStyle(theme.secondaryForeground)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    deityChip(nil, label: "None")
                    ForEach(Deity.allCases) { deity in
                        deityChip(deity, label: deity.displayName)
                    }
                }
            }
        }
    }

    // Visually secondary, clearly optional, never blocks progression.
    private var momentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What moments matter most? (optional)")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryForeground)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(curatedMoments) { item in
                        momentChip(item)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var reminderSection: some View {
        Toggle(isOn: $remindersOn) {
            Text("Remind me for morning or evening prayer")
                .font(.subheadline)
                .foregroundStyle(theme.foreground)
        }
        .tint(theme.accent)
    }

    // MARK: Chip builders

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(theme.foreground)
    }

    private func deityChip(_ deity: Deity?, label: String) -> some View {
        let isSelected = ishta == deity
        return Button {
            ishta = deity
        } label: {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(isSelected ? theme.accent : Color.white.opacity(0.12))
                .foregroundStyle(isSelected ? Color(hex: "1A1208") : theme.foreground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func momentChip(_ item: OnboardingMoment) -> some View {
        let isSelected = favoriteMoments.contains(item.moment)
        return Button {
            if isSelected { favoriteMoments.remove(item.moment) }
            else { favoriteMoments.insert(item.moment) }
        } label: {
            Text(item.label)
                .font(.caption)               // smaller — secondary to deity/mode
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? theme.accent.opacity(0.85) : Color.white.opacity(0.08))
                .foregroundStyle(isSelected ? Color(hex: "1A1208") : theme.secondaryForeground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Finish

    private func finish() {
        settings.scriptPreference = script
        settings.preferredPrayerMode = mode
        settings.ishtaDevata = ishta
        settings.favoriteMoments = Array(favoriteMoments)

        guard remindersOn else {
            complete()
            return
        }

        // Only request OS permission when the user opted in.
        Task { @MainActor in
            let granted = await NotificationManager.shared.requestAuthorization()
            if granted {
                let slots: Set<ReminderSlot> = [.dawn, .sunset]
                settings.enabledReminders = slots
                NotificationManager.shared.sync(enabledSlots: slots)
                complete()
            } else {
                // Denied: note gently and continue — never block onboarding.
                showReminderDeniedNote = true
            }
        }
    }

    private func complete() {
        if reduceMotion { settings.hasCompletedOnboarding = true }
        else { withAnimation { settings.hasCompletedOnboarding = true } }
    }
}
