import Foundation
import Supabase

@MainActor
struct AuthService {
    private var supabase: SupabaseClient { SupabaseClientProvider.shared.client }

    struct SignedInUser: Equatable {
        let id: UUID
        let email: String?
    }

    func currentUser() async -> SignedInUser? {
        do {
            let session = try await supabase.auth.session
            let user = session.user
            return SignedInUser(id: user.id, email: user.email)
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

    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            // ignore
        }
    }
}
