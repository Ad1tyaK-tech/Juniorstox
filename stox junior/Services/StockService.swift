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
        let cacheKey = "90d.v3.\(realTicker)"

        if let raw    = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode(AnalysisCache.self, from: raw),
           cached.dateString == today,
           let analysis = PriceAnalyzer.analyze(closePrices: cached.closePrices) {
            return analysis
        }

        // Build a unique 90-day history by compounding one seeded return per calendar
        // day. Start from the compounded price at day 90 so the chart reflects genuine
        // long-term drift rather than always orbiting the fixed base price.
        var closes = [Double]()
        closes.reserveCapacity(90)
        var runningPrice = compoundedPrice(ticker: realTicker, to: Self.dateString(daysBack: 90))
        for daysBack in stride(from: 89, through: 0, by: -1) {
            let dayStr = Self.dateString(daysBack: daysBack)
            let ret    = seededDailyReturn(ticker: realTicker, dateString: dayStr)
            runningPrice = max(1.0, runningPrice * (1.0 + ret))
            if runningPrice > 500.0 { runningPrice /= 2.0 }
            closes.append(runningPrice)
        }

        // Rescale so the series ends exactly at today's compounded price.
        let todayPrice = compoundedPrice(ticker: realTicker, to: today)
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
        let (seeded, splitMult) = compoundedInfo(ticker: alias.realTicker, to: dateString)
        let intraRange  = seeded * 0.015

        let floor = compoundedPrice(ticker: alias.realTicker, to: Self.yesterdayString())
        // recentlySplit: true if the split multiplier grew within the last 7 days.
        let recentlySplit = splitMult > compoundedInfo(ticker: alias.realTicker, to: Self.dateString(daysBack: 7)).splitMultiplier

        // 5-day trailing momentum: average seeded return over the last 5 calendar days.
        // A stock that has consistently moved in one direction gets a strong push in
        // that same direction — making trending stocks feel genuinely driven by momentum.
        // ±1.5%/day average → ±15 percentage-point boost on the displayed change.
        let momentum5d = (1...5).reduce(0.0) { sum, i in
            sum + seededDailyReturn(ticker: alias.realTicker, dateString: Self.dateString(daysBack: i))
        } / 5.0
        let momentumPriceImpact = seeded * momentum5d * 2.5

        // Seeded daily opening amplifier — one roll per (ticker, date), same for all users.
        // Roll is uniform [-10, 10]: 0 = flat open, ±10 = maximum drama.
        // Volatility multiplier scales the actual % impact by price tier:
        //   cheap/small stocks (e.g. PLY $42)  → multiplier ~4.8 → roll 10 = ~48% swing
        //   large-cap stocks   (e.g. NMV $891) → multiplier  0.5 → roll 10 =   5% swing
        let openRoll         = seededOpenAmplifier(ticker: alias.realTicker, dateString: dateString)
        let volMult          = volatilityMultiplier(basePrice: base)
        let openShockPercent = openRoll * volMult           // display-percent change from opening roll
        let openShockPrice   = seeded * (openShockPercent / 100.0)

        // Price: seeded anchor + opening shock + intraday noise + momentum drift.
        let bias = dailyReturn >= 0 ? 1.0 : -1.0
        let normalTick = Double.random(in: -maxTick...maxTick) * 0.3
                       + bias * Double.random(in: 0...maxTick * 0.3)
        let amplifier: Double = Double.random(in: 0..<1) < 0.10
            ? Double.random(in: -10...10)
            : 0
        let shockImpact  = seeded * (amplifier * 0.006)
        let displayPrice = max(1.0, seeded + openShockPrice + normalTick + shockImpact + momentumPriceImpact)

        // True day-over-day percentage change: how much did the price move vs yesterday's close.
        let changePercent = floor > 0 ? ((displayPrice - floor) / floor) * 100.0 : 0.0
        let slopeRate     = changePercent / 5.0

        return Stock(
            symbol:          alias.displaySymbol,
            company:         alias.displayCompany,
            realTicker:      alias.realTicker,
            price:           displayPrice,
            changePercent:   changePercent,
            trend:           changePercent >= 0 ? "Increasing" : "Decreasing",
            slopeRate:       slopeRate,
            maxima:          max(displayPrice, seeded + intraRange),
            minima:          max(1.0, min(displayPrice, seeded - intraRange)),
            floor:           floor,
            splitMultiplier: splitMult,
            recentlySplit:   recentlySplit
        )
    }

    // The date from which all prices begin compounding.
    // Base prices in sampleStocks represent the price on this date.
    private static let priceEpoch = "2025-01-01"

    // Compounds the base price forward from priceEpoch to dateString.
    // When the price exceeds $500 a 2:1 split fires: price is halved and splitMultiplier doubles.
    // Returns the adjusted price and cumulative split multiplier (1 = never split, 2 = once, …).
    private func compoundedInfo(ticker: String, to dateString: String) -> (price: Double, splitMultiplier: Int) {
        let base = basePriceFor(ticker)
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        guard let epochDate  = fmt.date(from: Self.priceEpoch),
              let targetDate = fmt.date(from: dateString) else { return (base, 1) }
        let days = max(0, Calendar.current.dateComponents([.day], from: epochDate, to: targetDate).day ?? 0)
        var price = base
        var splitMultiplier = 1
        for i in 0..<days {
            guard let d = Calendar.current.date(byAdding: .day, value: i, to: epochDate) else { continue }
            let dayStr = fmt.string(from: d)
            price = max(1.0, price * (1.0 + seededDailyReturn(ticker: ticker, dateString: dayStr)))
            if price > 500.0 {
                price /= 2.0
                splitMultiplier *= 2
            }
        }
        return (price, splitMultiplier)
    }

    private func compoundedPrice(ticker: String, to dateString: String) -> Double {
        compoundedInfo(ticker: ticker, to: dateString).price
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

    // LCG-seeded uniform roll in [-10, 10] for (ticker, date).
    // Appending "dawn" keeps this independent of seededDailyReturn's seed stream.
    private func seededOpenAmplifier(ticker: String, dateString: String) -> Double {
        var s = (ticker + dateString + "dawn").unicodeScalars
            .reduce(UInt64(0)) { $0 &* 31 &+ UInt64($1.value) } | 1
        s = s &* 6364136223846793005 &+ 1442695040888963407
        let u = Double(s >> 33) / Double(UInt64(1) << 31) // [0, 2)
        return (u - 1.0) * 10.0                           // [-10, 10)
    }

    // Maps a stock's base price to a volatility multiplier.
    // Lower-priced stocks are treated as more volatile: the same roll value produces
    // a much larger percentage swing than it would for a high-priced large-cap.
    private func volatilityMultiplier(basePrice: Double) -> Double {
        min(5.0, max(0.5, 200.0 / basePrice))
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
