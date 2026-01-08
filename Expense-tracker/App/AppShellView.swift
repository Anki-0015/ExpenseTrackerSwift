import SwiftUI
import Supabase
import Auth

struct AppShellView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.route {
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
        .onOpenURL { url in
            SupabaseClientProvider.shared.client.auth.handle(url)
        }
    }
}

#Preview {
    AppShellView()
        .environment(AppState())
}
