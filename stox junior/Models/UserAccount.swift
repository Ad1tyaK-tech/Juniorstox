import SwiftData
import Foundation
import CryptoKit

@Model
final class UserAccount {

    @Attribute(.unique) var username: String
    var passwordHash: String
    var cashBalance: Double
    var sharesOwnedJSON: String
    var purchasePricesJSON: String
    var netWorthHistoryJSON: String
    var lastSnapshotDate: Date
    var createdDate: Date
    var dailyChallengeJSON: String = "{}"
    var achievementsJSON: String = "{}"
    var settingsJSON: String = "{}"

    init(username: String, password: String) {
        self.username = username
        self.passwordHash = Self.hash(password)
        self.cashBalance = 10_000
        self.sharesOwnedJSON = "{}"
        self.purchasePricesJSON = "{}"
        self.netWorthHistoryJSON = "[]"
        self.lastSnapshotDate = .now
        self.createdDate = .now
        self.dailyChallengeJSON = "{}"
    }

    func passwordMatches(_ input: String) -> Bool {
        Self.hash(input) == passwordHash
    }

    static func hash(_ text: String) -> String {
        let digest = SHA256.hash(data: Data(text.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
