import Foundation

/// Pure, stateless math engine — no networking, no side effects.
/// Feed it a slice of closing prices and get back a fully populated PriceAnalysis.
struct PriceAnalyzer {

    /// Returns nil when fewer than 3 data points are supplied.
    static func analyze(closePrices: [Double]) -> PriceAnalysis? {
        let n = closePrices.count
        guard n >= 3 else { return nil }

        // MARK: SMA (20-day)
        // Average of the last min(20, n) closing prices.
        let smaWindow = min(20, n)
        let sma = closePrices.suffix(smaWindow).reduce(0, +) / Double(smaWindow)

        // MARK: Linear Regression Slope
        // Ordinary least-squares on (day_index, close_price) pairs.
        // slope = (n·Σxy − Σx·Σy) / (n·Σx² − (Σx)²)
        var sumX = 0.0, sumY = 0.0, sumXY = 0.0, sumX2 = 0.0
        for (i, price) in closePrices.enumerated() {
            let x = Double(i)
            sumX  += x
            sumY  += price
            sumXY += x * price
            sumX2 += x * x
        }
        let nd = Double(n)
        let denom = nd * sumX2 - sumX * sumX
        let slope = denom == 0 ? 0.0 : (nd * sumXY - sumX * sumY) / denom

        // MARK: Volatility
        // Compute simple daily returns: (P_i − P_{i−1}) / P_{i−1}
        // Then take the sample standard deviation and scale to annual: σ × √252
        var returns: [Double] = []
        for i in 1..<n {
            let prev = closePrices[i - 1]
            guard prev > 0 else { continue }
            returns.append((closePrices[i] - prev) / prev)
        }

        let volatility: Double
        if returns.count >= 2 {
            let mean = returns.reduce(0, +) / Double(returns.count)
            let variance = returns
                .map { ($0 - mean) * ($0 - mean) }
                .reduce(0, +) / Double(returns.count - 1)
            volatility = sqrt(variance) * sqrt(252)
        } else {
            volatility = 0
        }

        // MARK: Local Extrema
        // A point is a local max if it is strictly greater than both neighbors;
        // a local min if strictly less than both neighbors.
        var localMaxima: [Double] = []
        var localMinima: [Double] = []
        for i in 1..<(n - 1) {
            let prev = closePrices[i - 1]
            let curr = closePrices[i]
            let next = closePrices[i + 1]
            if curr > prev && curr > next {
                localMaxima.append(curr)
            } else if curr < prev && curr < next {
                localMinima.append(curr)
            }
        }

        // MARK: Trend Signal
        // Bullish:  price above 20-day SMA AND slope positive  (momentum + structure agree)
        // Bearish:  price below 20-day SMA AND slope negative  (both point down)
        // Neutral:  signals conflict
        let current = closePrices[n - 1]
        let trendSignal: TrendSignal
        switch (current > sma, slope > 0) {
        case (true,  true):  trendSignal = .bullish
        case (false, false): trendSignal = .bearish
        default:             trendSignal = .neutral
        }

        return PriceAnalysis(
            closePrices: closePrices,
            sma: sma,
            slope: slope,
            volatility: volatility,
            localMaxima: localMaxima,
            localMinima: localMinima,
            trendSignal: trendSignal
        )
    }

    /// Builds a plausible 90-day closing-price series from a single day's quote.
    /// The series is anchored so its last value equals currentPrice and its overall
    /// drift matches changePercent. The pattern is deterministic per ticker so it
    /// stays visually stable across intraday price refreshes.
    static func syntheticPrices(
        currentPrice: Double,
        changePercent: Double,
        dayHigh: Double,
        dayLow: Double,
        ticker: String
    ) -> [Double] {
        let count = 90

        // Daily volatility estimated from the intraday range (simplified Parkinson estimator).
        let dailyVol = max(0.006, (dayHigh - dayLow) / max(1.0, currentPrice) * 0.5)

        // Deterministic LCG seeded from the ticker string — stable across refreshes.
        var state = ticker.unicodeScalars.reduce(UInt64(0)) { $0 &* 31 &+ UInt64($1.value) } | 1
        func nextNoise() -> Double {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return Double(state >> 33) / Double(UInt64(1) << 31) - 1.0  // uniform -1…1
        }

        // Distribute the total 90-day change evenly as a daily drift component.
        let totalReturn = changePercent / 100.0
        let dailyDrift  = totalReturn / Double(count)
        let startPrice  = max(1.0, currentPrice / (1.0 + totalReturn))

        var prices = [Double](repeating: 0.0, count: count)
        prices[0] = startPrice
        for i in 1..<count {
            prices[i] = max(1.0, prices[i - 1] * (1.0 + dailyDrift + nextNoise() * dailyVol))
        }

        // Rescale so the series ends exactly at currentPrice.
        let scale = currentPrice / prices[count - 1]
        return prices.map { max(1.0, $0 * scale) }
    }
}
