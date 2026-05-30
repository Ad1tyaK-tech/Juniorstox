import SwiftUI
internal import Combine

@MainActor
class AppState: ObservableObject {

    @Published var authState: AuthState = .welcome

    @Published var cashBalance: Double = 10000
    @Published var fullName: String = ""
    @Published var profileImage: UIImage? = nil

    // Start with the sample data so the UI never looks empty.
    // refreshMarket() replaces this with live data from Finnhub.
    @Published var marketStocks: [Stock] = sampleStocks
    @Published var ownedStocks: [Stock] = []
    @Published var portfolioHistory: [Double] = [10000]

    @Published var isRefreshing: Bool = false
    @Published var lastRefreshError: String? = nil

    private let stockService = StockService()

    func recordPortfolioValue() {
        portfolioHistory.append(cashBalance)
    }

    // Pulls fresh prices from Finnhub. Safe to call on launch or pull-to-refresh.
    // Keeps the existing sample data on screen if the network call fails.
    // Retries up to 3 times with increasing delays to handle cold-start network lag.
    func refreshMarket() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        lastRefreshError = nil

        var fetched: [Stock] = []
        for attempt in 0..<3 {
            if attempt > 0 {
                try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_500_000_000)
            }
            fetched = await stockService.fetchAllStocks()
            if !fetched.isEmpty { break }
        }

        if fetched.isEmpty {
            lastRefreshError = "Couldn't reach the market. Showing sample data."
        } else {
            marketStocks = fetched
            lastRefreshError = nil
        }
        isRefreshing = false
    }
}
