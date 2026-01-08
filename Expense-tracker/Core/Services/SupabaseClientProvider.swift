import Foundation
import Supabase

/// Shared Supabase client.
/// Keep usage behind services to make it easier to swap/disable later.
@MainActor
final class SupabaseClientProvider {
    static let shared = SupabaseClientProvider()

    let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(supabaseURL: SupabaseConfig.url, supabaseKey: SupabaseConfig.anonKey)
    }
}
