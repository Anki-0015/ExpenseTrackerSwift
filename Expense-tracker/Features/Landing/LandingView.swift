import SwiftUI

struct LandingView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        // Home/Landing has been removed from the app flow.
        // Keep this view as a placeholder only (to avoid breaking the Xcode project file reference).
        Color.clear
            .task {
                appState.route = .main
            }
    }
}

#Preview {
    LandingView()
        .environment(AppState())
}
