import SwiftUI
import Supabase
import Auth

struct AppShellView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isSignedIn, appState.route == .main {
                AppLockGateView {
                    RootView()
                }
            } else {
                AuthView()
            }
        }
        .task {
            await appState.bootstrapSessionIfNeeded()
        }
        .onOpenURL { url in
            SupabaseClientProvider.shared.client.auth.handle(url)
        }
    }
}

#Preview {
    AppShellView()
        .environment(AppState())
}
