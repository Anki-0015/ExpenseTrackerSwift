import SwiftUI

struct RootView: View {
    @State private var selected: Tab = .dashboard

    enum Tab: String, CaseIterable, Identifiable {
        case dashboard
        case review
        case timeline
        case profile

        var id: String { rawValue }
    }

    var body: some View {
        TabView(selection: $selected) {
            DashboardView()
                .tabItem { Label("Home", systemImage: "square.grid.2x2") }
                .tag(Tab.dashboard)

            ReviewView()
                .tabItem { Label("Review", systemImage: "checklist") }
                .tag(Tab.review)

            TimelineView()
                .tabItem { Label("Timeline", systemImage: "clock.arrow.circlepath") }
                .tag(Tab.timeline)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(Tab.profile)
        }
    }
}
