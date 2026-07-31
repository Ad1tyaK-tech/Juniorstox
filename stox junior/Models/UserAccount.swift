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

    // nonisolated so it's callable from any actor context (AccountService, etc.)
    nonisolated init(username: String, passwordHash: String) {
        self.username     = username
        self.passwordHash = passwordHash
    }

    // Explicit implementations replace synthesized ones, removing @MainActor inference.
    nonisolated init(from decoder: any Decoder) throws {
        let c           = try decoder.container(keyedBy: CodingKeys.self)
        username            = try c.decode(String.self, forKey: .username)
        passwordHash        = try c.decode(String.self, forKey: .passwordHash)
        cashBalance         = try c.decodeIfPresent(Double.self, forKey: .cashBalance)        ?? 10_000
        startingBalance     = try c.decodeIfPresent(Double.self, forKey: .startingBalance)    ?? 10_000
        sharesOwnedJSON     = try c.decodeIfPresent(String.self, forKey: .sharesOwnedJSON)    ?? "{}"
        purchasePricesJSON  = try c.decodeIfPresent(String.self, forKey: .purchasePricesJSON) ?? "{}"
        netWorthHistoryJSON = try c.decodeIfPresent(String.self, forKey: .netWorthHistoryJSON) ?? "[]"
        lastSnapshotDate    = try c.decodeIfPresent(Date.self,   forKey: .lastSnapshotDate)   ?? .now
        createdDate         = try c.decodeIfPresent(Date.self,   forKey: .createdDate)        ?? .now
        dailyChallengeJSON  = try c.decodeIfPresent(String.self, forKey: .dailyChallengeJSON) ?? "{}"
        achievementsJSON    = try c.decodeIfPresent(String.self, forKey: .achievementsJSON)   ?? "{}"
        settingsJSON        = try c.decodeIfPresent(String.self, forKey: .settingsJSON)       ?? "{}"
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(username,            forKey: .username)
        try c.encode(passwordHash,        forKey: .passwordHash)
        try c.encode(cashBalance,         forKey: .cashBalance)
        try c.encode(startingBalance,     forKey: .startingBalance)
        try c.encode(sharesOwnedJSON,     forKey: .sharesOwnedJSON)
        try c.encode(purchasePricesJSON,  forKey: .purchasePricesJSON)
        try c.encode(netWorthHistoryJSON, forKey: .netWorthHistoryJSON)
        try c.encode(lastSnapshotDate,    forKey: .lastSnapshotDate)
        try c.encode(createdDate,         forKey: .createdDate)
        try c.encode(dailyChallengeJSON,  forKey: .dailyChallengeJSON)
        try c.encode(achievementsJSON,    forKey: .achievementsJSON)
        try c.encode(settingsJSON,        forKey: .settingsJSON)
    }

    nonisolated func passwordMatches(_ input: String) -> Bool {
        Self.hash(input) == passwordHash
    }

    nonisolated static func hash(_ text: String) -> String {
        let digest = SHA256.hash(data: Data(text.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
