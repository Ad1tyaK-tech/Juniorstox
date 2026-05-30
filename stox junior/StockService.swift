import Foundation

// Talks to Finnhub's /quote endpoint.
// Docs: https://finnhub.io/docs/api/quote
//
// Response shape:
//   c  = current price
//   d  = change in dollars vs previous close
//   dp = change in percent vs previous close
//   h  = day high
//   l  = day low
//   o  = day open
//   pc = previous close
private struct FinnhubQuote: Decodable {
    let c: Double
    let d: Double?
    let dp: Double?
    let h: Double
    let l: Double
    let o: Double
    let pc: Double
}

enum StockServiceError: Error {
    case badURL
    case badResponse
    case emptyQuote   // Finnhub returns all zeros for an unknown / closed-market ticker
}

struct StockService {

    // Multiplies the real day-change % for a more exciting display.
    // Direction stays accurate; magnitude is amplified.
    private let changeAmplifier: Double = 3.0

    // Max random intraday price tick added on each refresh (±$).
    // Biased toward the day's real direction so it feels natural.
    private let maxTick: Double = 10.0

    private let apiKey: String

    init(apiKey: String = Secrets.finnhubAPIKey) {
        self.apiKey = apiKey
    }

    // Fetches a live quote for every aliased ticker and converts each one into
    // a Stock with the kid-friendly display name applied.
    func fetchAllStocks() async -> [Stock] {

        // Run all requests in parallel using a TaskGroup — much faster than serial.
        await withTaskGroup(of: Stock?.self) { group in

            for alias in stockAliases {
                group.addTask {
                    do {
                        return try await fetchStock(for: alias)
                    } catch {
                        print("[StockService] fetch failed for \(alias.realTicker): \(error)")
                        return nil
                    }
                }
            }

            var results: [Stock] = []
            for await stock in group {
                if let stock { results.append(stock) }
            }
            // Preserve the original order from stockAliases for a stable UI.
            return results.sorted { lhs, rhs in
                let lhsIndex = stockAliases.firstIndex { $0.realTicker == lhs.realTicker } ?? 0
                let rhsIndex = stockAliases.firstIndex { $0.realTicker == rhs.realTicker } ?? 0
                return lhsIndex < rhsIndex
            }
        }
    }

    private func fetchStock(for alias: StockAlias) async throws -> Stock {
        let quote = try await fetchQuote(ticker: alias.realTicker)

        let realChange = quote.dp ?? 0
        let amplifiedChange = realChange * changeAmplifier

        // Bias the random tick toward the real day direction so movement feels natural.
        let directionBias = realChange >= 0 ? 1.0 : -1.0
        let randomTick = Double.random(in: -maxTick...maxTick) * 0.5
                       + directionBias * Double.random(in: 0...maxTick * 0.5)
        let displayPrice = max(1.0, quote.c + randomTick)

        return Stock(
            symbol: alias.displaySymbol,
            company: alias.displayCompany,
            realTicker: alias.realTicker,
            price: displayPrice,
            changePercent: amplifiedChange,
            trend: amplifiedChange >= 0 ? "Increasing" : "Decreasing",
            slopeRate: amplifiedChange / 5,
            maxima: quote.h + abs(randomTick),
            minima: max(1.0, quote.l - abs(randomTick)),
            floor: quote.pc
        )
    }

    private func fetchQuote(ticker: String) async throws -> FinnhubQuote {

        var components = URLComponents(string: "https://finnhub.io/api/v1/quote")
        components?.queryItems = [
            URLQueryItem(name: "symbol", value: ticker),
            URLQueryItem(name: "token", value: apiKey),
        ]
        guard let url = components?.url else { throw StockServiceError.badURL }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw StockServiceError.badResponse
        }

        let quote = try JSONDecoder().decode(FinnhubQuote.self, from: data)

        // Finnhub returns c=0 for invalid symbols or rate-limited responses.
        guard quote.c > 0 else { throw StockServiceError.emptyQuote }

        return quote
    }
}
