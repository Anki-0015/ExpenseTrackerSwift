import SwiftUI

struct LandingView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()

                Text("Expense Tracker")
                    .font(.largeTitle.bold())

                Text("Track spending. Stay in control.")
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    Task { await continueTapped() }
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.authStatus == .unknown)

                if appState.authStatus == .unknown {
                    ProgressView()
                }
            }
            .padding()
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }

    @MainActor
    private func continueTapped() async {
        await appState.bootstrapSessionIfNeeded()

        switch appState.authStatus {
        case .unknown:
            return
        case .signedOut:
            appState.route = .auth
        case .signedIn:
            appState.route = .main
        }
    }
}

#Preview {
    LandingView()
        .environment(AppState())
}
