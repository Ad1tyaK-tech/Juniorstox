import Foundation
import CryptoKit

// Plain Codable struct — persisted in Supabase, not SwiftData.
// CodingKeys map to the snake_case column names in the accounts table.
struct UserAccount: Codable {

    var username: String
    var passwordHash: String
    var cashBalance: Double = 10_000
    var startingBalance: Double = 10_000
    var sharesOwnedJSON: String = "{}"
    var purchasePricesJSON: String = "{}"
    var netWorthHistoryJSON: String = "[]"
    var lastSnapshotDate: Date = .now
    var createdDate: Date = .now
    var dailyChallengeJSON: String = "{}"
    var achievementsJSON: String = "{}"
    var settingsJSON: String = "{}"

    enum CodingKeys: String, CodingKey {
        case username
        case passwordHash        = "password_hash"
        case cashBalance         = "cash_balance"
        case startingBalance     = "starting_balance"
        case sharesOwnedJSON     = "shares_owned_json"
        case purchasePricesJSON  = "purchase_prices_json"
        case netWorthHistoryJSON = "net_worth_history_json"
        case lastSnapshotDate    = "last_snapshot_at"
        case createdDate         = "created_at"
        case dailyChallengeJSON  = "daily_challenge_json"
        case achievementsJSON    = "achievements_json"
        case settingsJSON        = "settings_json"
    }

    init(username: String, passwordHash: String) {
        self.username     = username
        self.passwordHash = passwordHash
    }

    func passwordMatches(_ input: String) -> Bool {
        Self.hash(input) == passwordHash
    }

    static func hash(_ text: String) -> String {
        let digest = SHA256.hash(data: Data(text.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
