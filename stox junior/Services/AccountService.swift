import Foundation

enum AccountError: LocalizedError {
    case badURL
    case network(Int)
    case notFound
    case wrongPassword
    case usernameTaken
    case emailTaken
    case decodingFailed
    case rpcError(String)
    case unauthorized   // no session token, or token expired/invalid on the server

    var errorDescription: String? {
        switch self {
        case .badURL:           return "Invalid Supabase URL — check Secrets.swift."
        case .network(let c):   return "Network error (\(c)). Check your connection."
        case .notFound:         return "No account found with that username."
        case .wrongPassword:    return "Wrong password. Try again."
        case .usernameTaken:    return "That name is already taken. Try a different one."
        case .emailTaken:       return "That email is already linked to another account."
        case .decodingFailed:   return "Could not read account data."
        case .rpcError:         return "Server error. Please try again."
        case .unauthorized:     return "Session expired. Please log in again."
        }
    }
}

// Actor — all Supabase account operations, thread-safe.
// Every operation goes through a SECURITY DEFINER RPC; no direct table access.
actor AccountService {

    private let base:    String
    private let anonKey: String
    private let session = URLSession.shared

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // Session token stored here and mirrored to UserDefaults so it survives app restarts.
    // The token only authorises access to this user's simulated portfolio — not real financial data.
    // Keychain would be more secure for apps handling sensitive data.
    private static let tokenKey = "session.token"
    private(set) var sessionToken: UUID?

    init(url: String, anonKey: String) {
        base         = url
        self.anonKey = anonKey

        // Restore session token from previous launch
        if let raw  = UserDefaults.standard.string(forKey: Self.tokenKey),
           let uuid = UUID(uuidString: raw) {
            sessionToken = uuid
        }

        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .custom { dec in
            let c = try dec.singleValueContainer()
            let s = try c.decode(String.self)
            let frac = ISO8601DateFormatter()
            frac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = frac.date(from: s) { return d }
            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            if let d = plain.date(from: s) { return d }
            throw DecodingError.dataCorrupted(
                .init(codingPath: dec.codingPath, debugDescription: "Bad date: \(s)")
            )
        }
        decoder = dec
    }

    // MARK: - Session

    private func storeToken(_ token: UUID) {
        sessionToken = token
        UserDefaults.standard.set(token.uuidString, forKey: Self.tokenKey)
    }

    func clearSession() {
        sessionToken = nil
        UserDefaults.standard.removeObject(forKey: Self.tokenKey)
    }

    // MARK: - Auth

    func login(username: String, password: String) async throws -> UserAccount {
        do {
            let rows: [UserAccount] = try await rpc("login_account",
                                                    body: ["p_username": username,
                                                           "p_password": password])
            guard let account = rows.first else { throw AccountError.wrongPassword }
            if let token = account.sessionToken { storeToken(token) }
            return account
        } catch AccountError.rpcError(let msg) {
            switch msg {
            case "not_found":      throw AccountError.notFound
            case "wrong_password": throw AccountError.wrongPassword
            default:               throw AccountError.network(0)
            }
        }
    }

    // Re-fetches account data for a user who already authenticated in a prior session.
    // Requires a valid session token from the previous login.
    func fetchAccount(username: String) async throws -> UserAccount {
        guard let token = sessionToken else { throw AccountError.unauthorized }
        struct Body: Encodable {
            let p_username:      String
            let p_session_token: String
        }
        let rows: [UserAccount] = try await rpc("fetch_account",
                                                body: Body(p_username:      username,
                                                           p_session_token: token.uuidString))
        guard let account = rows.first else { throw AccountError.notFound }
        return account
    }

    func createAccount(username: String, password: String) async throws -> UserAccount {
        do {
            let rows: [UserAccount] = try await rpc("create_account",
                                                    body: ["p_username": username,
                                                           "p_password": password])
            guard let created = rows.first else { throw AccountError.decodingFailed }
            if let token = created.sessionToken { storeToken(token) }
            return created
        } catch AccountError.rpcError(let msg) where msg == "username_taken" {
            throw AccountError.usernameTaken
        }
    }

    // MARK: - Persistence

    func save(_ account: UserAccount) async throws {
        guard let token = sessionToken else { throw AccountError.unauthorized }
        struct Body: Encodable {
            let p_session_token:          String
            let p_keycode_hash:           String
            let p_cash_balance:           Double
            let p_starting_balance:       Double
            let p_shares_owned_json:      String
            let p_purchase_prices_json:   String
            let p_net_worth_history_json: String
            let p_last_snapshot_at:       Date
            let p_daily_challenge_json:   String
            let p_achievements_json:      String
            let p_settings_json:          String
        }
        try await rpcVoid("save_account", body: Body(
            p_session_token:          token.uuidString,
            p_keycode_hash:           account.keycodeHash,
            p_cash_balance:           account.cashBalance,
            p_starting_balance:       account.startingBalance,
            p_shares_owned_json:      account.sharesOwnedJSON,
            p_purchase_prices_json:   account.purchasePricesJSON,
            p_net_worth_history_json: account.netWorthHistoryJSON,
            p_last_snapshot_at:       account.lastSnapshotDate,
            p_daily_challenge_json:   account.dailyChallengeJSON,
            p_achievements_json:      account.achievementsJSON,
            p_settings_json:          account.settingsJSON
        ))
    }

    func delete(username: String) async throws {
        guard let token = sessionToken else { throw AccountError.unauthorized }
        struct Body: Encodable { let p_session_token: String }
        try await rpcVoid("delete_account", body: Body(p_session_token: token.uuidString))
        clearSession()
    }

    // MARK: - Password Recovery

    // Returns only the username for a matching keycode — no account data, no password hash.
    func findUsernameByKeycode(_ hash: String) async throws -> String? {
        guard !hash.isEmpty else { return nil }
        struct Row: Decodable { let username: String }
        let rows: [Row] = try await rpc("find_username_by_keycode",
                                        body: ["p_keycode_hash": hash])
        return rows.first?.username
    }

    func isKeycodeTaken(_ hash: String) async throws -> Bool {
        try await findUsernameByKeycode(hash) != nil
    }

    // Atomically resets the password and invalidates all sessions for that account.
    // The keycode hash is the credential for this operation (user is locked out of their session).
    func resetPassword(keycodeHash: String, newPasswordHash: String) async throws -> String {
        struct Body: Encodable {
            let p_keycode_hash:      String
            let p_new_password_hash: String
        }
        struct Row: Decodable { let username: String }
        do {
            let rows: [Row] = try await rpc("reset_password",
                                            body: Body(p_keycode_hash:      keycodeHash,
                                                       p_new_password_hash: newPasswordHash))
            guard let row = rows.first else { throw AccountError.notFound }
            return row.username
        } catch AccountError.rpcError(let msg) where msg == "not_found" {
            throw AccountError.notFound
        }
    }

    // MARK: - RPC Helpers

    private func rpc<T: Decodable, B: Encodable>(_ name: String, body: B) async throws -> T {
        guard let url = URL(string: "\(base)/rest/v1/rpc/\(name)") else {
            throw AccountError.badURL
        }
        var req = baseRequest(url, method: "POST")
        req.httpBody = try encoder.encode(body)
        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            if let errBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = errBody["message"] as? String {
                throw AccountError.rpcError(msg)
            }
            throw AccountError.network(http.statusCode)
        }
        guard let result = try? decoder.decode(T.self, from: data) else {
            throw AccountError.decodingFailed
        }
        return result
    }

    private func rpcVoid<B: Encodable>(_ name: String, body: B) async throws {
        guard let url = URL(string: "\(base)/rest/v1/rpc/\(name)") else {
            throw AccountError.badURL
        }
        var req = baseRequest(url, method: "POST")
        req.httpBody = try encoder.encode(body)
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { return }
        if !(200..<300).contains(http.statusCode) {
            if let errBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = errBody["message"] as? String {
                throw AccountError.rpcError(msg)
            }
            throw AccountError.network(http.statusCode)
        }
    }

    private func baseRequest(_ url: URL, method: String) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return req
    }
}
