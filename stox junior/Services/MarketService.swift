import Foundation

struct MarketPriceRow: Codable {
    var ticker:        String
    var price:         Double
    var changePercent: Double
    var trend:         String
    var slopeRate:     Double
    var maxima:        Double
    var minima:        Double
    var floor:         Double
    var updatedAt:     Date

    enum CodingKeys: String, CodingKey {
        case ticker
        case price
        case changePercent = "change_percent"
        case trend
        case slopeRate     = "slope_rate"
        case maxima
        case minima
        case floor
        case updatedAt     = "updated_at"
    }
}

// Handles reads and writes to the shared market_prices Supabase table.
//
// Run this SQL once in the Supabase SQL editor:
//
//   create table market_prices (
//     ticker         text primary key,
//     price          float8,
//     change_percent float8,
//     trend          text,
//     slope_rate     float8,
//     maxima         float8,
//     minima         float8,
//     floor          float8,
//     updated_at     timestamptz default now()
//   );
//   alter table market_prices enable row level security;
//   create policy "public read"  on market_prices for select using (true);
//   create policy "public write" on market_prices for all    using (true);
//
actor MarketService {

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

    func fetchMarketPrices() async -> [MarketPriceRow] {
        guard let url = URL(string: "\(base)/rest/v1/market_prices?select=*") else { return [] }
        guard let (data, resp) = try? await session.data(for: baseRequest(url, method: "GET")),
              let http = resp as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let rows = try? decoder.decode([MarketPriceRow].self, from: data) else { return [] }
        return rows
    }

    func upsertMarketPrices(_ rows: [MarketPriceRow]) async {
        guard let url = URL(string: "\(base)/rest/v1/market_prices?on_conflict=ticker") else { return }
        var req = baseRequest(url, method: "POST")
        req.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        req.httpBody = try? encoder.encode(rows)
        _ = try? await session.data(for: req)
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
