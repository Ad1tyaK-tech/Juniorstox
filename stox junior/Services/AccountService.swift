import Foundation

enum AccountError: LocalizedError {
    case badURL
    case network(Int)
    case notFound
    case wrongPassword
    case usernameTaken
    case emailTaken
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .badURL:           return "Invalid Supabase URL — check Secrets.swift."
        case .network(let c):   return "Network error (\(c)). Check your connection."
        case .notFound:         return "No account found with that username."
        case .wrongPassword:    return "Wrong password. Try again."
        case .usernameTaken:    return "That name is already taken. Try a different one."
        case .emailTaken:       return "That email is already linked to another account."
        case .decodingFailed:   return "Could not read account data."
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

    init() {
        base    = Secrets.supabaseURL
        anonKey = Secrets.supabaseAnonKey

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
        let rows: [UserAccount] = try await fetch("accounts?username=eq.\(pct(username))&select=*")
        guard let account = rows.first else { throw AccountError.notFound }
        guard account.passwordMatches(password) else { throw AccountError.wrongPassword }
        return account
    }

    func createAccount(username: String, password: String) async throws -> UserAccount {
        // Uniqueness check
        let existing: [[String: String]] = try await fetch(
            "accounts?username=eq.\(pct(username))&select=username"
        )
        guard existing.isEmpty else { throw AccountError.usernameTaken }

        let account = UserAccount(username: username, passwordHash: UserAccount.hash(password))
        return try await insert(account)
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

    // Fetches the account whose settingsJSON contains the given email (stored as linkedEmail).
    func findByEmail(_ email: String) async throws -> UserAccount? {
        let all: [UserAccount] = try await fetch("accounts?select=*")
        let target = email.trimmingCharacters(in: .whitespaces).lowercased()
        struct EmailCheck: Decodable { var linkedEmail: String = "" }
        return all.first {
            guard let d = $0.settingsJSON.data(using: .utf8),
                  let c = try? JSONDecoder().decode(EmailCheck.self, from: d) else { return false }
            return c.linkedEmail.trimmingCharacters(in: .whitespaces).lowercased() == target
        }
    }

    func isEmailTaken(_ email: String) async throws -> Bool {
        try await findByEmail(email) != nil
    }

    // MARK: - Helpers

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
