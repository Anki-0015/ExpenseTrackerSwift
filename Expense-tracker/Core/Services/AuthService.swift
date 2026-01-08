import Foundation
import Supabase

@MainActor
struct AuthService {
    private var supabase: SupabaseClient { SupabaseClientProvider.shared.client }
    
    struct SessionInfo: Equatable {
        let user: SignedInUser
        let accessToken: String
        let refreshToken: String?
        let expiresAt: Date?
    }
    
    struct SignedInUser: Equatable {
        let id: UUID
        let email: String?
    }
    
    func currentUser() async -> SignedInUser? {
        await currentSessionInfo()?.user
    }
    
    func currentSessionInfo() async -> SessionInfo? {
        do {
            let session = try await supabase.auth.session
            return SessionInfo(
                user: SignedInUser(id: session.user.id, email: session.user.email),
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                expiresAt: Date(timeIntervalSince1970: session.expiresAt)
            )
        } catch {
            return nil
        }
    }

    func signUp(email: String, password: String) async throws -> SignedInUser {
        let response = try await supabase.auth.signUp(email: email, password: password)
        let user = response.user
        return SignedInUser(id: user.id, email: user.email)
    }

    func signIn(email: String, password: String) async throws -> SignedInUser {
        let session = try await supabase.auth.signIn(email: email, password: password)
        let user = session.user
        return SignedInUser(id: user.id, email: user.email)
    }

    func sendPasswordResetEmail(email: String, redirectTo: URL) async throws {
        try await supabase.auth.resetPasswordForEmail(email, redirectTo: redirectTo)
    }

    func updatePassword(newPassword: String) async throws {
        try await supabase.auth.update(user: UserAttributes(password: newPassword))
    }

    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            // ignore
        }
    }
}
