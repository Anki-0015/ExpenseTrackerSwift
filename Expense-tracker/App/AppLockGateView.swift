import SwiftUI

struct AppLockGateView<Content: View>: View {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase

    @State private var unlockedOnce = false
    @State private var errorMessage: String?

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Group {
            if !appState.settings.appLockEnabled {
                content
            } else if unlockedOnce {
                content
            } else {
                lockedView
            }
        }
        .onAppear {
            Task { await unlockIfNeeded() }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await unlockIfNeeded() }
            } else if newPhase == .background {
                // Re-lock when leaving the app.
                if appState.settings.appLockEnabled {
                    unlockedOnce = false
                }
            }
        }
        .onChange(of: appState.settings.appLockEnabled) { _, enabled in
            if enabled {
                unlockedOnce = false
                Task { await unlockIfNeeded() }
            }
        }
    }

    private var lockedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("Locked")
                .font(.title2.weight(.semibold))

            Text(errorMessage ?? "Authenticate to access your Expense OS.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await unlockIfNeeded(force: true) }
            } label: {
                Text("Unlock")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 24)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private func unlockIfNeeded(force: Bool = false) async {
        guard appState.settings.appLockEnabled else {
            unlockedOnce = true
            return
        }
        guard !unlockedOnce || force else { return }

        let service = AppLockService()
        let result = await service.unlock(reason: "Unlock Expense OS")
        switch result {
        case .unlocked:
            errorMessage = nil
            unlockedOnce = true
        case .unavailable:
            // If device auth isn't available, do not block the user indefinitely.
            errorMessage = "Device authentication unavailable."
            unlockedOnce = true
        case .failed(let message):
            errorMessage = message
            unlockedOnce = false
        }
    }
}
