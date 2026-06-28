import SwiftUI
import SwiftData

/// The Me tab: preferences, reminders, and saved prayers.
struct MeView: View {
    @EnvironmentObject private var library: PrayerLibrary
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var coordinator: AppCoordinator

    @Query(sort: \FavoritePrayer.savedAt, order: .reverse) private var favorites: [FavoritePrayer]

    @StateObject private var notifications = NotificationManager.shared
    @State private var notificationsDenied = false

    // Local mirrors so SwiftUI re-renders on change.
    @State private var script: ScriptPreference = .both
    @State private var mode: PlayMode = .listen
    @State private var ishta: Deity?
    @State private var favoriteMoments: Set<Moment> = []
    @State private var enabledReminders: Set<ReminderSlot> = []

    var body: some View {
        NavigationStack {
            Form {
                scriptSection
                modeSection
                ishtaSection
                momentsSection
                remindersSection
                savedSection
                aboutSection
            }
            .navigationTitle("Me")
            .onAppear(perform: loadState)
        }
    }

    // MARK: Sections

    private var scriptSection: some View {
        Section("Script") {
            Picker("Show text as", selection: $script) {
                ForEach(ScriptPreference.allCases) { Text($0.displayName).tag($0) }
            }
            .onChange(of: script) { _, value in settings.scriptPreference = value }
        }
    }

    private var modeSection: some View {
        Section("Preferred mode") {
            Picker("Pray with", selection: $mode) {
                ForEach(PlayMode.allCases) { Text($0.displayName).tag($0) }
            }
            .onChange(of: mode) { _, value in settings.preferredPrayerMode = value }
        }
    }

    private var ishtaSection: some View {
        Section {
            Picker("Ishta devata", selection: $ishta) {
                Text("None").tag(Deity?.none)
                ForEach(Deity.allCases) { deity in
                    Text(deity.displayName).tag(Deity?.some(deity))
                }
            }
            .onChange(of: ishta) { _, value in settings.ishtaDevata = value }
        } header: {
            Text("Ishta devata")
        } footer: {
            Text("Prayers to this deity are gently favoured on Today.")
        }
    }

    private var momentsSection: some View {
        Section {
            ForEach(Moment.allCases) { moment in
                Button {
                    toggleMoment(moment)
                } label: {
                    HStack {
                        Label(moment.displayName, systemImage: moment.symbolName)
                            .foregroundStyle(.primary)
                        Spacer()
                        if favoriteMoments.contains(moment) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
        } header: {
            Text("Favourite moments")
        } footer: {
            Text("Chosen moments shape what Today suggests.")
        }
    }

    private var remindersSection: some View {
        Section {
            ForEach(ReminderSlot.allCases) { slot in
                Toggle(isOn: bindingForReminder(slot)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(slot.title)
                        Text(String(format: "%02d:%02d", slot.defaultHour, slot.defaultMinute))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if notificationsDenied {
                Text("Notifications are turned off in Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("Local reminders only. Nothing leaves your device.")
        }
    }

    private var savedSection: some View {
        Section("Saved prayers") {
            if savedPrayers.isEmpty {
                Text("Prayers you save will rest here.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(savedPrayers) { prayer in
                    Button {
                        coordinator.play(prayer)
                    } label: {
                        PrayerRow(prayer: prayer)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteSaved)
            }
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Anjali")
                Spacer()
                Text("A sacred pause, not a session.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Helpers

    private var savedPrayers: [Prayer] {
        favorites.compactMap { library.prayer(withID: $0.prayerID) }
    }

    private func loadState() {
        script = settings.scriptPreference
        mode = settings.preferredPrayerMode
        ishta = settings.ishtaDevata
        favoriteMoments = Set(settings.favoriteMoments)
        enabledReminders = settings.enabledReminders
        // @MainActor so the @State mutation after the await stays on the main thread.
        Task { @MainActor in
            let status = await notifications.authorizationStatus()
            notificationsDenied = (status == .denied)
        }
    }

    private func toggleMoment(_ moment: Moment) {
        if favoriteMoments.contains(moment) {
            favoriteMoments.remove(moment)
        } else {
            favoriteMoments.insert(moment)
        }
        settings.favoriteMoments = Array(favoriteMoments)
    }

    private func bindingForReminder(_ slot: ReminderSlot) -> Binding<Bool> {
        Binding(
            get: { enabledReminders.contains(slot) },
            set: { isOn in
                Task { await setReminder(slot, enabled: isOn) }
            }
        )
    }

    @MainActor
    private func setReminder(_ slot: ReminderSlot, enabled: Bool) async {
        if enabled {
            let granted = await notifications.requestAuthorization()
            guard granted else {
                notificationsDenied = true
                return
            }
            enabledReminders.insert(slot)
        } else {
            enabledReminders.remove(slot)
        }
        settings.enabledReminders = enabledReminders
        notifications.sync(enabledSlots: enabledReminders)
    }

    private func deleteSaved(at offsets: IndexSet) {
        let prayersToRemove = offsets.map { savedPrayers[$0] }
        let ids = Set(prayersToRemove.map(\.id))
        for favorite in favorites where ids.contains(favorite.prayerID) {
            modelContext.delete(favorite)
        }
        try? modelContext.save()
    }

    @Environment(\.modelContext) private var modelContext
}
