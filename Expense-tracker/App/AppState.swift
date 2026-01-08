import Foundation
import Observation
import Supabase

@Observable
final class AppState {
    private let store = UserDefaultsStore()

    private(set) var settings: AppSettings

    enum AppRoute: Equatable {
        case auth
        case main
    }

    enum AuthStatus: Equatable {
        case unknown
        case signedOut
        case signedIn(userId: UUID, email: String?)
    }

    enum AuthSheet: Equatable, Identifiable {
        case passwordRecovery

        var id: String {
            switch self {
            case .passwordRecovery: return "passwordRecovery"
            }
        }
    }

    // Offline-first: the app is usable without auth; auth is an optional route.
    var route: AppRoute = .main
    private(set) var authStatus: AuthStatus = .unknown

    // Session/JWT snapshot (in-memory)
    private(set) var accessTokenJWT: String?
    private(set) var refreshToken: String?
    private(set) var tokenExpiresAt: Date?

    // Used to present auth-related flows.
    var authSheet: AuthSheet?

    private var didBootstrapSession: Bool = false

    private var authListenerTask: Task<Void, Never>?

    init() {
        self.settings = store.load(AppSettings.self, key: "app.settings", defaultValue: .default)
    }

    func updateSettings(_ update: (inout AppSettings) -> Void) {
        var copy = settings
        update(&copy)
        settings = copy
        store.save(settings, key: "app.settings")
    }

    @MainActor
    func bootstrapSessionIfNeeded() async {
        guard !didBootstrapSession else { return }
        didBootstrapSession = true

        startListeningToAuthChangesIfNeeded()
        await SupabaseClientProvider.shared.client.auth.startAutoRefresh()

        let auth = AuthService()

        // Best-effort initial snapshot (the auth event stream will also update this).
        if let sessionInfo = await auth.currentSessionInfo() {
            updateFromSessionInfo(sessionInfo)
        } else {
            authStatus = .signedOut
            accessTokenJWT = nil
            refreshToken = nil
            tokenExpiresAt = nil
        }
    }

    private func startListeningToAuthChangesIfNeeded() {
        guard authListenerTask == nil else { return }

        authListenerTask = Task {
            let client = await SupabaseClientProvider.shared.client

            for await (event, session) in await client.auth.authStateChanges {
                await MainActor.run {
                    self.handleAuthEvent(event, session: session)
                }
            }
        }
    }

    private func handleAuthEvent(_ event: AuthChangeEvent, session: Session?) {
        // Keep a cached JWT in memory.
        if let session {
            accessTokenJWT = session.accessToken
            refreshToken = session.refreshToken
            tokenExpiresAt = Date(timeIntervalSince1970: session.expiresAt)
        }

        switch event {
        case .initialSession:
            if let session {
                authStatus = .signedIn(userId: session.user.id, email: session.user.email)
            } else {
                authStatus = .signedOut
            }

        case .signedIn:
            if let session {
                authStatus = .signedIn(userId: session.user.id, email: session.user.email)
                route = .main
                authSheet = nil
            }

        case .tokenRefreshed:
            if let session {
                authStatus = .signedIn(userId: session.user.id, email: session.user.email)
            }

        case .signedOut:
            authStatus = .signedOut
            accessTokenJWT = nil
            refreshToken = nil
            tokenExpiresAt = nil
            authSheet = nil
            route = .auth

        case .passwordRecovery:
            // Show UI to update the password.
            route = .auth
            authSheet = .passwordRecovery

        default:
            break
        }
    }

    private func updateFromSessionInfo(_ info: AuthService.SessionInfo) {
        authStatus = .signedIn(userId: info.user.id, email: info.user.email)
        accessTokenJWT = info.accessToken
        refreshToken = info.refreshToken
        tokenExpiresAt = info.expiresAt
    }

    @MainActor
    func setSignedIn(userId: UUID, email: String?) {
        authStatus = .signedIn(userId: userId, email: email)
        route = .main
    }

    @MainActor
    func setSignedOut() {
        authStatus = .signedOut
        route = .auth
    }
}
