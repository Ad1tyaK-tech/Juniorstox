// Template for Secrets.swift (which is gitignored).
//
// To set up the project locally:
//   1. Create a file called "Secrets.swift" next to this one.
//   2. Paste the contents below into it (remove the #if false wrapper).
//   3. Replace each placeholder with your real keys.
//
// Where to get each key:
//   - finnhubAPIKey        → finnhub.io → Dashboard
//   - alphaadvantageAPIKey → alphavantage.co → "Get free API key"
//   - supabaseURL          → Supabase project → Settings → API → Project URL
//   - supabaseAnonKey      → Supabase project → Settings → API → anon public key
//
// Do NOT commit Secrets.swift — only this example file is safe to commit.
//
// The #if false below makes this whole file invisible to the compiler,
// so it won't conflict with the real Secrets.swift.

#if false
import Foundation

enum Secrets {
    static let finnhubAPIKey        = "REPLACE_WITH_YOUR_FINNHUB_KEY"
    static let alphaadvantageAPIKey = "REPLACE_WITH_YOUR_ALPHAVANTAGE_KEY"

    // Supabase — read-only anon key is safe in the app binary.
    // NEVER put the service_role key here.
    static let supabaseURL     = "https://YOUR_PROJECT_REF.supabase.co"
    static let supabaseAnonKey = "REPLACE_WITH_YOUR_SUPABASE_ANON_KEY"
}
#endif
