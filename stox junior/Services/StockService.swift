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

    // Displayed change is amplified 5× for excitement.
    // Direction stays true; only the magnitude is exaggerated.
    private let changeAmplifier: Double = 3.0

    // Max random intraday tick (±$) added when generating fresh prices.
    private let maxTick: Double = 18.0

    // allowsCellularAccess kept for API compatibility with AppState's settings toggle.
    init(allowsCellularAccess: Bool = true) {}

    // MARK: - Public API

    // Generates a fresh set of prices with a new amplifier roll on every open/refresh
    // and writes them to Supabase immediately, so every other user sees the update
    // on their next pull-to-refresh or app open.
    func fetchAllStocks(using marketService: MarketService) async -> [Stock] {
        let today   = Self.todayString()
        let stocks  = stockAliases.map { syntheticStock(for: $0, dateString: today) }
        let newRows = stocks.map { stock in
            MarketPriceRow(
                ticker:        stock.realTicker,
                price:         stock.price,
                changePercent: stock.changePercent,
                trend:         stock.trend,
                slopeRate:     stock.slopeRate,
                maxima:        stock.maxima,
                minima:        stock.minima,
                floor:         stock.floor,
                updatedAt:     .now
            )
        }
        await marketService.upsertMarketPrices(newRows)
        return stocks
    }

    // Returns a 90-day PriceAnalysis for a ticker.
    // Caches to UserDefaults so the chart is generated only once per calendar day.
    func fetchPriceAnalysis(for realTicker: String) async throws -> PriceAnalysis {
        let today    = Self.todayString()
        let cacheKey = "90d.v2.\(realTicker)"

        if let raw    = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode(AnalysisCache.self, from: raw),
           cached.dateString == today,
           let analysis = PriceAnalyzer.analyze(closePrices: cached.closePrices) {
            return analysis
        }

        // Build a unique 90-day history by compounding one seeded return per calendar
        // day. Each (ticker, date) pair produces a different return, so cumulative paths
        // diverge naturally across stocks — giving visually distinct charts.
        let base = basePriceFor(realTicker)
        var closes = [Double]()
        closes.reserveCapacity(90)
        var runningPrice = base
        for daysBack in stride(from: 89, through: 0, by: -1) {
            let dayStr = Self.dateString(daysBack: daysBack)
            let ret    = seededDailyReturn(ticker: realTicker, dateString: dayStr)
            runningPrice = max(1.0, runningPrice * (1.0 + ret))
            closes.append(runningPrice)
        }

        // Rescale so the series ends exactly at today's seeded price.
        let todayPrice = max(1.0, base * (1.0 + seededDailyReturn(ticker: realTicker, dateString: today)))
        if let last = closes.last, last > 0 {
            let scale = todayPrice / last
            closes = closes.map { max(1.0, $0 * scale) }
        }

        if let encoded = try? JSONEncoder().encode(AnalysisCache(dateString: today, closePrices: closes)) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }

        guard let analysis = PriceAnalyzer.analyze(closePrices: closes) else {
            throw StockServiceError.emptyQuote
        }
        return analysis
    }

    // MARK: - Synthetic generation

    // Builds one Stock seeded by (ticker, date), with trajectory momentum and a
    // random shock amplifier layered on top. Both get saved to Supabase so all
    // users share the same state until the next hourly refresh.
    private func syntheticStock(for alias: StockAlias, dateString: String) -> Stock {
        let base        = basePriceFor(alias.realTicker)
        let dailyReturn = seededDailyReturn(ticker: alias.realTicker, dateString: dateString)
        let seeded      = max(1.0, base * (1.0 + dailyReturn))
        let intraRange  = seeded * 0.015

        let yesterdayReturn = seededDailyReturn(ticker: alias.realTicker, dateString: Self.yesterdayString())
        let floor = max(1.0, base * (1.0 + yesterdayReturn))

        // 5-day trailing momentum: average seeded return over the last 5 calendar days.
        // A stock that has consistently moved in one direction gets a strong push in
        // that same direction — making trending stocks feel genuinely driven by momentum.
        // ±1.5%/day average → ±15 percentage-point boost on the displayed change.
        let momentum5d = (1...5).reduce(0.0) { sum, i in
            sum + seededDailyReturn(ticker: alias.realTicker, dateString: Self.dateString(daysBack: i))
        } / 5.0
        let momentumChange      = momentum5d * 100.0 * 10.0  // ±1.5% avg → ±15%
        let momentumPriceImpact = seeded * momentum5d * 2.5  // ±1.5% avg → ±3.75% price shift

        // 10% chance per stock per fetch to fire a random amplifier in [-10, +10].
        // Negative values push the stock down; positive push it up.
        // The remaining 90% of fetches produce no amplifier effect.
        let amplifier: Double = Double.random(in: 0..<1) < 0.10
            ? Double.random(in: -10...10)
            : 0

        // Sum: seeded base move + 5-day momentum push + shock.
        // Cap at ±50 so values stay readable even on stacked extreme days.
        let baseChange  = dailyReturn * 100 * changeAmplifier
        let totalChange = min(50.0, max(-50.0, baseChange + momentumChange + amplifier * 2.5))
        let slopeRate   = totalChange / 5.0

        // Price: seeded anchor + larger random tick + shock impact + momentum drift.
        // ±10 amplifier → ±6% price move; ±1.5% momentum avg → ±3.75% price drift.
        let bias = dailyReturn >= 0 ? 1.0 : -1.0
        let normalTick = Double.random(in: -maxTick...maxTick) * 0.3
                       + bias * Double.random(in: 0...maxTick * 0.3)
        let shockImpact  = seeded * (amplifier * 0.006)
        let displayPrice = max(1.0, seeded + normalTick + shockImpact + momentumPriceImpact)

        return Stock(
            symbol:        alias.displaySymbol,
            company:       alias.displayCompany,
            realTicker:    alias.realTicker,
            price:         displayPrice,
            changePercent: totalChange,
            trend:         totalChange >= 0 ? "Increasing" : "Decreasing",
            slopeRate:     slopeRate,
            maxima:        max(displayPrice, seeded + intraRange),
            minima:        max(1.0, min(displayPrice, seeded - intraRange)),
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

    private static func dateString(daysBack: Int) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Calendar.current.date(byAdding: .day, value: -daysBack, to: .now)!)
    }
}
