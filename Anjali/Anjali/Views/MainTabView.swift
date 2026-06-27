import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.and.horizon") }
                .tag(AppTab.today)

            MomentsView()
                .tabItem { Label("Moments", systemImage: "square.grid.2x2") }
                .tag(AppTab.moments)

            MeView()
                .tabItem { Label("Me", systemImage: "person") }
                .tag(AppTab.me)
        }
    }
}
