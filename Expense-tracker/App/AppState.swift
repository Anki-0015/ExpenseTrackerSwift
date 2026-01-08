import Foundation
import Observation

@Observable
final class AppState {
    private let store = UserDefaultsStore()

    private(set) var settings: AppSettings

    enum AppRoute: Equatable {
        case landing
        case auth
        case main
    }

    enum AuthStatus: Equatable {
        case unknown
        case signedOut
        case signedIn(userId: UUID, email: String?)
    }

    var route: AppRoute = .landing
    private(set) var authStatus: AuthStatus = .unknown

    private var didBootstrapSession: Bool = false

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

        let auth = AuthService()
        if let user = await auth.currentUser() {
            authStatus = .signedIn(userId: user.id, email: user.email)
        } else {
            authStatus = .signedOut
        }
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
