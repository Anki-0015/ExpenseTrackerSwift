import Foundation

/// Configure your Supabase project here.
///
/// You can find these values in the Supabase dashboard:
/// - Project Settings → API → Project URL
/// - Project Settings → API → Project API keys → anon public
///
/// Note: The anon key is safe to embed in a client app when you use RLS policies.
enum SupabaseConfig {

    private static let urlString: String = "https://admwovklyvasrrdjhnxi.supabase.co"


    private static let anonKeyString: String = "sb_publishable_L8DkhUxfZ5aLRf4rE5O8GA_4FwVgH0Z"

    static var url: URL {
        guard !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = URL(string: urlString) else {
            fatalError("Supabase not configured: set SupabaseConfig.urlString to your Project URL (Supabase dashboard → Project Settings → API → Project URL).")
        }
        return url
    }

    static var anonKey: String {
        let key = anonKeyString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            fatalError("Supabase not configured: set SupabaseConfig.anonKeyString to your anon public key (Supabase dashboard → Project Settings → API → Project API keys → anon public).")
        }
        return key
    }
}
