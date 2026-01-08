import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    enum Mode: Equatable {
        case signIn
        case signUp
    }

    enum State: Equatable {
        case signedOut
        case signedIn(userId: UUID, email: String?)
    }

    var mode: Mode = .signIn
    var state: State = .signedOut

    var email: String = ""
    var password: String = ""

    var fullName: String = ""

    var isLoading: Bool = false
    var message: String?

    private let auth = AuthService()
    private let profiles = ProfileService()

    func loadCurrentUser() async {
        isLoading = true
        defer { isLoading = false }

        if let user = await auth.currentUser() {
            state = .signedIn(userId: user.id, email: user.email)
            email = user.email ?? ""
            await loadProfile(userId: user.id)
        } else {
            state = .signedOut
        }
    }

    func submitAuth() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            message = "Enter email and password."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let user: AuthService.SignedInUser
            switch mode {
            case .signIn:
                user = try await auth.signIn(email: trimmedEmail, password: trimmedPassword)
            case .signUp:
                user = try await auth.signUp(email: trimmedEmail, password: trimmedPassword)
            }

            message = nil
            state = .signedIn(userId: user.id, email: user.email)

            // Ensure a profile row exists.
            let profile = UserProfile(id: user.id, email: user.email, fullName: fullName.isEmpty ? nil : fullName)
            try await profiles.upsertProfile(profile)

            await loadProfile(userId: user.id)
        } catch {
            message = error.localizedDescription
        }
    }

    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        await auth.signOut()
        password = ""
        fullName = ""
        message = nil
        state = .signedOut
    }

    func saveProfile() async {
        guard case let .signedIn(userId, email) = state else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let updated = UserProfile(id: userId, email: email, fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : fullName)
            try await profiles.upsertProfile(updated)
            message = "Saved."
        } catch {
            message = error.localizedDescription
        }
    }

    private func loadProfile(userId: UUID) async {
        do {
            if let profile = try await profiles.fetchProfile(userId: userId) {
                fullName = profile.fullName ?? ""
            }
        } catch {
            // Non-fatal; keep UI usable even if table isn't set up yet.
            message = "Profile table not ready: \(error.localizedDescription)"
        }
    }
}
