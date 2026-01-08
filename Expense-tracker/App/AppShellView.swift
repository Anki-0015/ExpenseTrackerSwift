import SwiftUI

struct AppShellView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.route {
            case .landing:
                LandingView()
            case .auth:
                AuthView()
            case .main:
                AppLockGateView {
                    RootView()
                }
            }
        }
        .task {
            await appState.bootstrapSessionIfNeeded()
        }
    }
}

#Preview {
    AppShellView()
        .environment(AppState())
}
