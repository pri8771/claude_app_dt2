import SwiftUI
import SwiftData

/// Full-screen prayer player. Listen / Chant use an audio-style layout; Silent
/// uses a distinct, minimal reading layout. Records a completion in SwiftData.
struct PrayerPlayerView: View {
    let prayer: Prayer
    /// When set, the player opens locked to this mode (Today card "Silent").
    let forcedMode: PlayMode?

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var controller: PlayerController
    @State private var mode: PlayMode
    @State private var showCompletion = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Today's theme drives the player background too.
    private let theme = ThemePalette.palette(for: TimeBandResolver.timeContext(for: Date()))

    init(prayer: Prayer, forcedMode: PlayMode? = nil) {
        self.prayer = prayer
        self.forcedMode = forcedMode
        let initialMode = forcedMode ?? prayer.playableModes.first ?? .silent
        _mode = State(initialValue: initialMode)
        _controller = StateObject(wrappedValue: PlayerController(prayer: prayer, mode: initialMode))
    }

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()

            if mode == .silent {
                silentContent
            } else {
                audioContent
            }
        }
        .preferredColorScheme(theme.prefersDarkForeground ? .light : .dark)
        .onAppear {
            applyInitialMode()
            handleSilentEntry()
        }
        .onChange(of: mode) { _, _ in handleSilentEntry() }
        .onChange(of: controller.isFinished) { _, finished in
            if finished {
                recordCompletion()
                if reduceMotion { showCompletion = true }
                else { withAnimation { showCompletion = true } }
            }
        }
        .onDisappear { controller.stop() }
        .overlay {
            if showCompletion {
                CompletionView(
                    prayer: prayer,
                    theme: theme,
                    onDone: finishAndClose,
                    onRepeat: repeatPrayer,
                    onSave: savePrayer
                )
                .transition(.opacity)
            }
        }
    }

    // MARK: Audio layout (Listen / Chant)

    private var audioContent: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 8)

            ScrollView {
                VStack(spacing: 22) {
                    Text(prayer.title)
                        .font(.system(.title2, design: .serif, weight: .semibold))
                        .foregroundStyle(theme.foreground)

                    PrayerTextView(
                        prayer: prayer,
                        scriptPreference: settings.scriptPreference,
                        theme: theme,
                        primaryStyle: .largeTitle
                    )

                    Text(prayer.meaning)
                        .font(.body)
                        .foregroundStyle(theme.secondaryForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 12)
            }

            Spacer(minLength: 8)

            FlameProgressView(progress: controller.progress, theme: theme)
                .frame(width: 120, height: 120)
                .padding(.bottom, 8)
                .accessibilityHidden(true)

            if mode == .listen && controller.audioUnavailable {
                Text("Audio isn't available — follow along in silence.")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryForeground)
            }

            if forcedMode == nil {
                modePicker.padding(.vertical, 14)
            }

            controls.padding(.bottom, 28)
        }
        .padding(.horizontal, 24)
    }

    // MARK: Silent layout (distinct, minimal, office-safe)

    private var silentContent: some View {
        VStack(spacing: 0) {
            topBar

            if forcedMode == nil {
                modePicker.padding(.vertical, 10)
            }

            Spacer(minLength: 12)

            ScrollView {
                VStack(spacing: 20) {
                    Text(prayer.title)
                        .font(.system(.title2, design: .serif, weight: .semibold))
                        .foregroundStyle(theme.foreground)

                    PrayerTextView(
                        prayer: prayer,
                        scriptPreference: settings.scriptPreference,
                        theme: theme,
                        primaryStyle: .largeTitle
                    )

                    Text(prayer.meaning)
                        .font(.body)
                        .foregroundStyle(theme.foreground.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 12)
            }

            Spacer(minLength: 12)

            silentProgressBar
                .padding(.bottom, 18)

            Button {
                controller.completeNow()
            } label: {
                Text("Complete").frame(maxWidth: .infinity)
            }
            .silentCompleteStyle(theme: theme)
            .accessibilityLabel("Complete prayer")
            .padding(.bottom, 28)
        }
        .padding(.horizontal, 24)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Silent prayer mode. Reading prayer text.")
    }

    /// A thin, calm progress bar — no glow, minimal motion.
    private var silentProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(theme.foreground.opacity(0.15))
                Capsule()
                    .fill(theme.accent)
                    .frame(width: geo.size.width * controller.progress)
            }
        }
        .frame(height: 4)
        .accessibilityElement()
        .accessibilityLabel("Prayer progress, \(Int((controller.progress * 100).rounded())) percent complete")
    }

    // MARK: Shared subviews

    private var topBar: some View {
        HStack {
            Button {
                controller.stop()
                coordinator.dismissPlayer()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(theme.foreground)
            }
            .accessibilityLabel("Close")
            Spacer()
            InfoChip(text: prayer.durationLabel, systemImage: "clock", tint: theme.accent)
                .accessibilityLabel("Duration: \(prayer.accessibleDuration)")
        }
        .padding(.top, 12)
    }

    private var modePicker: some View {
        HStack(spacing: 10) {
            ForEach(prayer.playableModes) { available in
                // ModeChip carries its own VoiceOver label + button/selected traits.
                ModeChip(mode: available, isSelected: available == mode, theme: theme) {
                    mode = available
                    controller.setMode(available)
                }
            }
        }
    }

    private var controls: some View {
        Button {
            if controller.isRunning {
                controller.pause()
            } else {
                controller.start()
            }
        } label: {
            HStack {
                Image(systemName: controller.isRunning ? "pause.fill" : "flame.fill")
                Text(controller.isRunning ? "Pause" : "Begin")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(AnjaliPrimaryButtonStyle(theme: theme))
        .accessibilityLabel(controller.isRunning ? "Pause" : "Begin prayer")
    }

    // MARK: Mode handling

    /// Resolve the opening mode: a forced mode (set in init) is locked;
    /// otherwise prefer the user's preferred mode when supported.
    private func applyInitialMode() {
        guard forcedMode == nil else { return }
        let preferred = settings.preferredPrayerMode
        guard prayer.playableModes.contains(preferred), preferred != mode else { return }
        mode = preferred
        controller.setMode(preferred)
    }

    /// Silent mode auto-starts its quiet reading timer and announces itself.
    private func handleSilentEntry() {
        guard mode == .silent else { return }
        if !controller.isRunning && !controller.isFinished {
            controller.start()
        }
        AccessibilityNotification.Announcement("Silent prayer mode. Reading prayer text.").post()
    }

    // MARK: Actions

    private func recordCompletion() {
        let completion = PrayerCompletion(prayerID: prayer.id, mode: mode, completedAt: Date())
        modelContext.insert(completion)
        try? modelContext.save()
    }

    private func finishAndClose() {
        coordinator.noteSessionCompletion(prayer.id)
        controller.stop()
        coordinator.dismissPlayer()
        dismiss()
    }

    private func repeatPrayer() {
        // The user explicitly wants this prayer again — do not deprioritise it.
        if reduceMotion { showCompletion = false }
        else { withAnimation { showCompletion = false } }
        controller.reset()
        controller.start()
    }

    private func savePrayer() {
        // Avoid duplicate favourites for the same prayer.
        let id = prayer.id
        let descriptor = FetchDescriptor<FavoritePrayer>(
            predicate: #Predicate { $0.prayerID == id }
        )
        let alreadySaved = (try? modelContext.fetch(descriptor))?.isEmpty == false
        if !alreadySaved {
            modelContext.insert(FavoritePrayer(prayerID: id, savedAt: Date()))
            try? modelContext.save()
        }
        coordinator.noteSessionCompletion(id)
        controller.stop()
        coordinator.dismissPlayer()
        dismiss()
    }
}

private extension View {
    /// Discreet styling for the Silent "Complete" CTA.
    func silentCompleteStyle(theme: ThemePalette) -> some View {
        self
            .font(.headline)
            .padding(.vertical, 14)
            .background(theme.foreground.opacity(0.12))
            .foregroundStyle(theme.foreground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .buttonStyle(.plain)
    }
}
