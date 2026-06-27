import SwiftUI
import SwiftData

/// Full-screen prayer player. Supports Listen / Chant / Silent, shows the
/// sacred text large, and records a completion in SwiftData.
struct PrayerPlayerView: View {
    let prayer: Prayer

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var controller: PlayerController
    @State private var mode: PlayMode
    @State private var showCompletion = false

    // Today's theme drives the player background too.
    private let theme = ThemePalette.palette(for: TimeBandResolver.timeContext(for: Date()))

    init(prayer: Prayer) {
        self.prayer = prayer
        // Always completable: falls back to Silent if no modes are listed.
        let initialMode = prayer.playableModes.first ?? .silent
        _mode = State(initialValue: initialMode)
        _controller = StateObject(wrappedValue: PlayerController(prayer: prayer, mode: initialMode))
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 8)

                ScrollView {
                    VStack(spacing: 22) {
                        Text(prayer.title)
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .foregroundStyle(theme.foreground)

                        PrayerTextView(
                            prayer: prayer,
                            scriptPreference: settings.scriptPreference,
                            theme: theme,
                            devanagariSize: 34
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

                if mode == .listen && controller.audioUnavailable {
                    Text("Audio isn't available — follow along in silence.")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryForeground)
                }

                modePicker
                    .padding(.vertical, 14)

                controls
                    .padding(.bottom, 28)
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(theme.prefersDarkForeground ? .light : .dark)
        .onChange(of: controller.isFinished) { _, finished in
            if finished {
                recordCompletion()
                withAnimation { showCompletion = true }
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

    // MARK: Subviews

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
            Spacer()
            InfoChip(text: prayer.durationLabel, systemImage: "clock", tint: theme.accent)
        }
        .padding(.top, 12)
    }

    private var modePicker: some View {
        HStack(spacing: 10) {
            ForEach(prayer.playableModes) { available in
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
        withAnimation { showCompletion = false }
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
