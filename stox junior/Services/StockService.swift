import Foundation

// Cached to UserDefaults so the chart is stable within a calendar day.
private struct AnalysisCache: Codable {
    let dateString: String    // "yyyy-MM-dd"
    let closePrices: [Double]
}

enum StockServiceError: Error {
    case emptyQuote
}

struct StockService {

    // Displayed change is amplified 3× for excitement.
    // Direction stays true; only the magnitude is exaggerated.
    private let changeAmplifier: Double = 3.0

    // Max random intraday tick (±$) added on each pull to simulate live movement.
    private let maxTick: Double = 8.0

    // allowsCellularAccess kept for API compatibility with AppState's settings toggle.
    init(allowsCellularAccess: Bool = true) {}

    // MARK: - Public API

    // Returns all stocks for today using a deterministic seed so every user sees
    // the same direction on the same calendar day. A small random tick is added on
    // top so prices "move" on each manual refresh.
    func fetchAllStocks() async -> [Stock] {
        let today = Self.todayString()
        return stockAliases.map { syntheticStock(for: $0, dateString: today) }
    }

    // Applies a small random tick to each stock — used by AppState's hourly timer
    // to keep the UI feeling live without any network call.
    func applySimulatedTicks(to stocks: [Stock]) -> [Stock] {
        stocks.map { stock in
            let bias = stock.changePercent >= 0 ? 1.0 : -1.0
            let tick = Double.random(in: -maxTick...maxTick) * 0.5
                     + bias * Double.random(in: 0...maxTick * 0.5)
            return Stock(
                symbol:        stock.symbol,
                company:       stock.company,
                realTicker:    stock.realTicker,
                price:         max(1.0, stock.price + tick),
                changePercent: stock.changePercent,
                trend:         stock.trend,
                slopeRate:     stock.slopeRate,
                maxima:        stock.maxima + abs(tick),
                minima:        max(1.0, stock.minima - abs(tick)),
                floor:         stock.floor
            )
        }
    }

    // Returns a 90-day PriceAnalysis for a ticker.
    // Caches to UserDefaults so the chart is generated only once per calendar day.
    func fetchPriceAnalysis(for realTicker: String) async throws -> PriceAnalysis {
        let today    = Self.todayString()
        let cacheKey = "90d.\(realTicker)"

        if let raw    = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode(AnalysisCache.self, from: raw),
           cached.dateString == today,
           let analysis = PriceAnalyzer.analyze(closePrices: cached.closePrices) {
            return analysis
        }

        let base        = basePriceFor(realTicker)
        let dailyReturn = seededDailyReturn(ticker: realTicker, dateString: today)
        let seeded      = max(1.0, base * (1.0 + dailyReturn))
        let intraRange  = seeded * 0.015

        let closes = PriceAnalyzer.syntheticPrices(
            currentPrice:  seeded,
            changePercent: dailyReturn * 100,
            dayHigh:       seeded + intraRange,
            dayLow:        max(1.0, seeded - intraRange),
            ticker:        realTicker
        )

        if let encoded = try? JSONEncoder().encode(AnalysisCache(dateString: today, closePrices: closes)) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }

        guard let analysis = PriceAnalyzer.analyze(closePrices: closes) else {
            throw StockServiceError.emptyQuote
        }
        return analysis
    }

    // MARK: - Synthetic generation

    // Builds one Stock seeded by (ticker, date). The seeded price determines
    // direction and magnitude; a small random tick on top varies each call.
    private func syntheticStock(for alias: StockAlias, dateString: String) -> Stock {
        let base        = basePriceFor(alias.realTicker)
        let dailyReturn = seededDailyReturn(ticker: alias.realTicker, dateString: dateString)
        let amplified   = dailyReturn * 100 * changeAmplifier
        let seeded      = max(1.0, base * (1.0 + dailyReturn))
        let intraRange  = seeded * 0.015

        // Yesterday's seeded price acts as the "floor" (support level).
        let yesterdayReturn = seededDailyReturn(ticker: alias.realTicker, dateString: Self.yesterdayString())
        let floor = max(1.0, base * (1.0 + yesterdayReturn))

        let bias = dailyReturn >= 0 ? 1.0 : -1.0
        let tick = Double.random(in: -maxTick...maxTick) * 0.3
                 + bias * Double.random(in: 0...maxTick * 0.3)
        let displayPrice = max(1.0, seeded + tick)

        return Stock(
            symbol:        alias.displaySymbol,
            company:       alias.displayCompany,
            realTicker:    alias.realTicker,
            price:         displayPrice,
            changePercent: amplified,
            trend:         amplified >= 0 ? "Increasing" : "Decreasing",
            slopeRate:     amplified / 5,
            maxima:        seeded + intraRange,
            minima:        max(1.0, seeded - intraRange),
            floor:         floor
        )
    }

    // LCG + Box-Muller → N(0, 0.015).
    // Seeded by ticker + date so all users see the same price direction on the same day.
    // Daily vol of 1.5% is realistic for large-cap stocks; amplified 3× for display.
    private func seededDailyReturn(ticker: String, dateString: String) -> Double {
        var s = (ticker + dateString).unicodeScalars
            .reduce(UInt64(0)) { $0 &* 31 &+ UInt64($1.value) } | 1
        s = s &* 6364136223846793005 &+ 1442695040888963407
        let u1 = max(1e-10, Double(s >> 33) / Double(UInt64(1) << 31))
        s = s &* 6364136223846793005 &+ 1442695040888963407
        let u2 = Double(s >> 33) / Double(UInt64(1) << 31)
        return sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2) * 0.015
    }

    private func basePriceFor(_ realTicker: String) -> Double {
        sampleStocks.first { $0.realTicker == realTicker }?.price ?? 100.0
    }

    private static func todayString() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: .now)
    }

    private static func yesterdayString() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Calendar.current.date(byAdding: .day, value: -1, to: .now)!)
    }
}
