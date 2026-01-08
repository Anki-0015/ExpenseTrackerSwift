import Foundation
import Observation

@MainActor
@Observable
final class AuthViewModel {
    enum Mode: Equatable {
        case signIn
        case signUp
    }

    var mode: Mode = .signIn

    var email: String = ""
    var password: String = ""
    var fullName: String = ""

    var isLoading: Bool = false
    var message: String?

    private let auth = AuthService()
    private let profiles = ProfileService()

    func submit() async -> AuthService.SignedInUser? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            message = "Enter email and password."
            return nil
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

            // Ensure a profile row exists.
            let profile = UserProfile(id: user.id, email: user.email, fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : fullName)
            try await profiles.upsertProfile(profile)

            // If confirm-email is enabled in Supabase, signUp() may not return a session.
            // Only treat as signed-in if a session exists.
            if mode == .signUp, await auth.currentUser() == nil {
                message = "Account created. Please confirm your email, then sign in."
                return nil
            }

            return user
        } catch {
            message = error.localizedDescription
            return nil
        }
    }
}
