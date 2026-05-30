import SwiftUI

struct Stock: Identifiable {

    let id = UUID()

    // The fun, kid-friendly ticker shown in the app (e.g. "ORG").
    let symbol: String
    // The fun, kid-friendly company name shown in the app (e.g. "Orange").
    let company: String
    // The real Finnhub ticker used behind the scenes for the API call (e.g. "AAPL").
    let realTicker: String

    let price: Double
    let changePercent: Double

    let trend: String
    let slopeRate: Double

    let maxima: Double
    let minima: Double
    let floor: Double
}

// MARK: - FUN-NAME ALIAS MAP
//
// Maps the real ticker (used for the Finnhub API call) to a fun display name
// and a fun display ticker. The kid never sees the real ticker.
struct StockAlias {
    let realTicker: String
    let displaySymbol: String
    let displayCompany: String
}

let stockAliases: [StockAlias] = [
    // High-level blue chips
    StockAlias(realTicker: "AAPL",  displaySymbol: "ORG", displayCompany: "Orange"),
    StockAlias(realTicker: "MSFT",  displaySymbol: "MDS", displayCompany: "Macrodense"),
    StockAlias(realTicker: "NVDA",  displaySymbol: "NMV", displayCompany: "Nmovia"),
    StockAlias(realTicker: "GOOG",  displaySymbol: "GEG", displayCompany: "Geggol"),
    StockAlias(realTicker: "AMZN",  displaySymbol: "BRZ", displayCompany: "Bravozon"),
    StockAlias(realTicker: "META",  displaySymbol: "ATE", displayCompany: "Atem Systems"),
    // Mid / volatile
    StockAlias(realTicker: "TSLA",  displaySymbol: "EIN", displayCompany: "Einstein"),
    StockAlias(realTicker: "AMD",   displaySymbol: "SMD", displayCompany: "Strong Mini Devices"),
    StockAlias(realTicker: "COIN",  displaySymbol: "DST", displayCompany: "Dollarstand"),
    StockAlias(realTicker: "RBLX",  displaySymbol: "PLY", displayCompany: "Playbit"),
]

// MARK: - SAMPLE DATA
//
// Used by SwiftUI previews and as an offline fallback if the network is unavailable.
// Field values intentionally look reasonable so previews render nicely.
let sampleStocks: [Stock] = [

    Stock(
        symbol: "ORG",
        company: "Orange",
        realTicker: "AAPL",
        price: 213.45,
        changePercent: 0.57,
        trend: "Increasing",
        slopeRate: 1.8,
        maxima: 214.10,
        minima: 211.80,
        floor: 200
    ),

    Stock(
        symbol: "MDS",
        company: "Macrodense",
        realTicker: "MSFT",
        price: 412.10,
        changePercent: -0.32,
        trend: "Decreasing",
        slopeRate: -0.4,
        maxima: 418.00,
        minima: 410.50,
        floor: 395
    ),

    Stock(
        symbol: "NMV",
        company: "Nmovia",
        realTicker: "NVDA",
        price: 891.55,
        changePercent: 2.71,
        trend: "Increasing",
        slopeRate: 2.7,
        maxima: 905.00,
        minima: 870.00,
        floor: 800
    ),

    Stock(
        symbol: "EIN",
        company: "Einstein",
        realTicker: "TSLA",
        price: 245.80,
        changePercent: -1.40,
        trend: "Decreasing",
        slopeRate: -0.9,
        maxima: 252.00,
        minima: 244.00,
        floor: 230
    ),

    Stock(
        symbol: "GEG",
        company: "Geggol",
        realTicker: "GOOG",
        price: 178.22,
        changePercent: 0.92,
        trend: "Increasing",
        slopeRate: 0.6,
        maxima: 180.00,
        minima: 176.40,
        floor: 165
    ),

    Stock(
        symbol: "BRZ",
        company: "Bravozon",
        realTicker: "AMZN",
        price: 191.30,
        changePercent: 0.64,
        trend: "Increasing",
        slopeRate: 0.6,
        maxima: 193.00,
        minima: 189.10,
        floor: 180.00
    ),

    Stock(
        symbol: "ATE",
        company: "Atem systems",
        realTicker: "META",
        price: 578.90,
        changePercent: -0.88,
        trend: "Decreasing",
        slopeRate: -0.88,
        maxima: 585.00,
        minima: 575.00,
        floor: 550.00
    ),

    Stock(
        symbol: "SMD",
        company: "Strong Mini Devices",
        realTicker: "AMD",
        price: 130.45,
        changePercent: 1.82,
        trend: "Increasing",
        slopeRate: 1.82,
        maxima: 133.20,
        minima: 128.50,
        floor: 125.00
    ),

    Stock(
        symbol: "DST",
        company: "Dollarstand",
        realTicker: "COIN",
        price: 242.15,
        changePercent: 3.45,
        trend: "Increasing",
        slopeRate: 3.45,
        maxima: 250.00,
        minima: 234.00,
        floor: 215.00
    ),

    Stock(
        symbol: "PLY",
        company: "Playbit",
        realTicker: "RBLX",
        price: 42.30,
        changePercent: -2.10,
        trend: "Decreasing",
        slopeRate: -2.10,
        maxima: 44.50,
        minima: 41.00,
        floor: 38.00
    ),
]
