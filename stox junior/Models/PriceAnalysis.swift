import Foundation

enum TrendSignal: String {
    case bullish = "Bullish"
    case neutral = "Neutral"
    case bearish = "Bearish"
}

struct PriceAnalysis {
    /// Chronological closing prices used as input (up to 90 trading days).
    let closePrices: [Double]
    /// Simple moving average of the most recent 20 closes.
    let sma: Double
    /// Ordinary least-squares slope across all closes, in dollars per trading day.
    let slope: Double
    /// Annualized volatility: standard deviation of daily returns × √252.
    let volatility: Double
    /// Closing prices that sit strictly above both their neighbors.
    let localMaxima: [Double]
    /// Closing prices that sit strictly below both their neighbors.
    let localMinima: [Double]
    /// Summary signal derived from the price-vs-SMA and slope direction.
    let trendSignal: TrendSignal
}
