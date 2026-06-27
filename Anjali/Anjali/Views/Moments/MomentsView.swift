import SwiftUI

/// Browse prayers by moment or by deity. No recommendations — just calm,
/// explicit shelves.
struct MomentsView: View {
    @EnvironmentObject private var library: PrayerLibrary
    @EnvironmentObject private var coordinator: AppCoordinator

    enum BrowseMode: String, CaseIterable, Identifiable {
        case moment = "Moment"
        case deity = "Deity"
        var id: String { rawValue }
    }

    @State private var browseMode: BrowseMode = .moment
    @State private var path: [Route] = []

    enum Route: Hashable {
        case moment(Moment)
        case deity(Deity)
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Picker("Browse", selection: $browseMode) {
                    ForEach(BrowseMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowSeparator(.hidden)

                switch browseMode {
                case .moment:
                    Section("Moments") {
                        ForEach(library.availableMoments) { moment in
                            NavigationLink(value: Route.moment(moment)) {
                                Label(moment.displayName, systemImage: moment.symbolName)
                            }
                        }
                    }
                case .deity:
                    Section("Deities") {
                        ForEach(library.availableDeities) { deity in
                            NavigationLink(value: Route.deity(deity)) {
                                Label(deity.displayName, systemImage: deity.symbolName)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Moments")
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .moment(let moment):
                    PrayerListView(
                        title: moment.displayName,
                        prayers: library.prayers(for: moment)
                    ) { coordinator.play($0) }
                case .deity(let deity):
                    PrayerListView(
                        title: deity.displayName,
                        prayers: library.prayers(for: deity)
                    ) { coordinator.play($0) }
                }
            }
        }
        .onChange(of: coordinator.pendingMoment) { _, moment in
            routeToPendingMoment(moment)
        }
        .onAppear {
            routeToPendingMoment(coordinator.pendingMoment)
        }
    }

    private func routeToPendingMoment(_ moment: Moment?) {
        guard let moment else { return }
        browseMode = .moment
        path = [.moment(moment)]
        coordinator.pendingMoment = nil
    }
}
