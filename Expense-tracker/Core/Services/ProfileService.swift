import Foundation
import Supabase

struct UserProfile: Codable, Equatable, Identifiable {
    let id: UUID
    var email: String?
    var fullName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
    }
}

@MainActor
struct ProfileService {
    private var supabase: SupabaseClient { SupabaseClientProvider.shared.client }

    func fetchProfile(userId: UUID) async throws -> UserProfile? {
        let response: UserProfile = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        return response
    }

    func upsertProfile(_ profile: UserProfile) async throws {
        _ = try await supabase
            .from("profiles")
            .upsert(profile, onConflict: "id")
            .execute()
    }
}
