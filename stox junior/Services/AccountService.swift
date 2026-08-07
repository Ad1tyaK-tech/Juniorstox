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
        }
    }
}

// Actor — all Supabase account operations, thread-safe.
actor AccountService {

    private let base:    String
    private let anonKey: String
    private let session = URLSession.shared

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(url: String, anonKey: String) {
        base        = url
        self.anonKey = anonKey

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

    // MARK: - Auth

    func login(username: String, password: String) async throws -> UserAccount {
        do {
            let rows: [UserAccount] = try await rpc("login_account", body: ["p_username": username, "p_password": password])
            guard let account = rows.first else { throw AccountError.wrongPassword }
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
    // No password check — the stored username is the trust anchor.
    func fetchAccount(username: String) async throws -> UserAccount {
        let rows: [UserAccount] = try await fetch("accounts?username=eq.\(pct(username))&select=*")
        guard let account = rows.first else { throw AccountError.notFound }
        return account
    }

    func createAccount(username: String, password: String) async throws -> UserAccount {
        do {
            let rows: [UserAccount] = try await rpc("create_account", body: ["p_username": username, "p_password": password])
            guard let created = rows.first else { throw AccountError.decodingFailed }
            return created
        } catch AccountError.rpcError(let msg) where msg == "username_taken" {
            throw AccountError.usernameTaken
        }
    }

    // MARK: - Persistence

    func save(_ account: UserAccount) async throws {
        guard let url = URL(string: "\(base)/rest/v1/accounts?username=eq.\(pct(account.username))") else {
            throw AccountError.badURL
        }
        var req = baseRequest(url, method: "PATCH")
        req.httpBody = try encoder.encode(account)
        let (_, resp) = try await session.data(for: req)
        try checkStatus(resp)
    }

    func delete(username: String) async throws {
        guard let url = URL(string: "\(base)/rest/v1/accounts?username=eq.\(pct(username))") else {
            throw AccountError.badURL
        }
        let (_, resp) = try await session.data(for: baseRequest(url, method: "DELETE"))
        try checkStatus(resp)
    }

    // MARK: - Password Recovery

    // Finds the account with a matching keycode_hash column (indexed — no full table scan).
    // Accepts the already-hashed value — raw keycodes must never be passed here.
    func findByKeycode(_ hash: String) async throws -> UserAccount? {
        guard !hash.isEmpty else { return nil }
        let rows: [UserAccount] = try await fetch("accounts?keycode_hash=eq.\(pct(hash))&select=*")
        return rows.first
    }

    func isKeycodeTaken(_ hash: String) async throws -> Bool {
        try await findByKeycode(hash) != nil
    }

    // MARK: - Helpers

    private func rpc<T: Decodable>(_ name: String, body: [String: String]) async throws -> T {
        guard let url = URL(string: "\(base)/rest/v1/rpc/\(name)") else { throw AccountError.badURL }
        var req = baseRequest(url, method: "POST")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            if let errBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = errBody["message"] as? String {
                throw AccountError.rpcError(msg)
            }
            throw AccountError.network(http.statusCode)
        }
        guard let result = try? decoder.decode(T.self, from: data) else { throw AccountError.decodingFailed }
        return result
    }

    private func fetch<T: Decodable>(_ path: String) async throws -> T {
        guard let url = URL(string: "\(base)/rest/v1/\(path)") else { throw AccountError.badURL }
        let (data, resp) = try await session.data(for: baseRequest(url, method: "GET"))
        try checkStatus(resp)
        guard let result = try? decoder.decode(T.self, from: data) else { throw AccountError.decodingFailed }
        return result
    }

    private func insert(_ account: UserAccount) async throws -> UserAccount {
        guard let url = URL(string: "\(base)/rest/v1/accounts") else { throw AccountError.badURL }
        var req = baseRequest(url, method: "POST")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        req.httpBody = try encoder.encode(account)
        let (data, resp) = try await session.data(for: req)
        try checkStatus(resp)
        let rows = try decoder.decode([UserAccount].self, from: data)
        guard let created = rows.first else { throw AccountError.decodingFailed }
        return created
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

    private func checkStatus(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw AccountError.network((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }

    private func pct(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
    }
}
