import SwiftUI

extension AppState {

    // MARK: - Net Worth

    var currentNetWorth: Int {
        let equityCents = ownedStocks.reduce(0) { sum, stock in
            let price = marketStocks.first { $0.realTicker == stock.realTicker }?.price ?? stock.price
            return sum + Int((price * Double(sharesOwned[stock.realTicker, default: 0]) * 100).rounded())
        }
        return cashBalance + equityCents
    }

    // MARK: - Trading

    @discardableResult
    func buyStock(_ stock: Stock, shares: Int) -> Bool {
        let cost = Int((stock.price * Double(shares) * 100).rounded())
        guard cost <= cashBalance else { return false }
        cashBalance -= cost

        let existing = sharesOwned[stock.realTicker, default: 0]
        let existingAvg = purchasePrices[stock.realTicker] ?? stock.price
        let newTotal = existing + shares
        purchasePrices[stock.realTicker] = (existingAvg * Double(existing) + stock.price * Double(shares)) / Double(newTotal)
        sharesOwned[stock.realTicker] = newTotal

        if !ownedStocks.contains(where: { $0.realTicker == stock.realTicker }) {
            ownedStocks.append(stock)
            holdingStartDates[stock.realTicker] = .now
        }

        // Achievement counters updated before snapshot so they're included in the save
        allTimeOwnedTickers.insert(stock.realTicker)
        maxSharesInOneTicker = max(maxSharesInOneTicker, sharesOwned[stock.realTicker, default: 0])
        if abs(stock.changePercent) >= 2.0              { volatileSharesBought  += shares }
        if abs(stock.changePercent) < 1.0 && stock.slopeRate > 0 { steadySharesBought += shares }
        if stock.changePercent >= 2.0                   { momentumSharesBought  += shares }
        if stock.price <= stock.floor * 1.05            { floorSharesBought     += shares }

        snapshotNetWorth()
        trackBuyForChallenge(stock: stock, shares: shares, cost: cost)
        return true
    }

    func sellStock(_ stock: Stock, shares: Int) {
        let buyPrice = purchasePrices[stock.realTicker] ?? stock.price
        cashBalance += Int((stock.price * Double(shares) * 100).rounded())
        if stock.price > buyPrice { profitSells += 1 }
        else if stock.price < buyPrice { lossSells += 1 }
        let remaining = (sharesOwned[stock.realTicker] ?? 0) - shares
        if remaining <= 0 {
            sharesOwned.removeValue(forKey: stock.realTicker)
            purchasePrices.removeValue(forKey: stock.realTicker)
            holdingStartDates.removeValue(forKey: stock.realTicker)
            ownedStocks.removeAll { $0.realTicker == stock.realTicker }
        } else {
            sharesOwned[stock.realTicker] = remaining
        }
        snapshotNetWorth()
        trackSellForChallenge(stock: stock)
    }

    // MARK: - Market Refresh

    func refreshMarket(silent: Bool = false) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        let fetched = await stockService.fetchAllStocks(using: marketService)
        if !fetched.isEmpty {
            marketStocks = fetched
            applySplitsIfNeeded(from: fetched)
            snapshotNetWorth()
        }
        isRefreshing = false
    }

    // MARK: - Split Adjustment

    // Compares each stock's current splitMultiplier to the last applied multiplier.
    // If it grew, the user's shares are doubled (and avg purchase price halved) for each
    // 2× increment, preserving total cost basis while reflecting the extra shares.
    func applySplitsIfNeeded(from stocks: [Stock]) {
        var didSplit = false
        for stock in stocks {
            let current = stock.splitMultiplier
            let applied = appliedSplitMultipliers[stock.realTicker, default: 1]
            // Always record the latest multiplier so future splits are detected correctly.
            appliedSplitMultipliers[stock.realTicker] = max(applied, current)
            guard current > applied, applied > 0 else { continue }
            guard sharesOwned[stock.realTicker] != nil else { continue }
            let ratio = current / applied
            sharesOwned[stock.realTicker]! *= ratio
            if let avgPrice = purchasePrices[stock.realTicker] {
                purchasePrices[stock.realTicker] = avgPrice / Double(ratio)
            }
            didSplit = true
        }
        if didSplit { snapshotNetWorth() }
        saveAppliedSplitMultipliers()
    }

    // MARK: - Portfolio Reset

    func resetPortfolio(startingBalance: Double) {
        let cents = Int((startingBalance * 100).rounded())
        cashBalance = cents
        self.startingBalance = cents
        sharesOwned = [:]
        purchasePrices = [:]
        ownedStocks = []
        netWorthHistory = [NetWorthSnapshot(date: .now, value: cents)]
        lastSnapshotDate = .now
        gems = 0
        challengeProgress = 0
        challengeClaimed = false
        challengeDateKey = ""
        netWorthAtDayStart = 0
        totalSpentToday = 0
        advancedDropdownTickers = []
        allTimeOwnedTickers = []
        maxSharesInOneTicker = 0
        volatileSharesBought = 0
        advancedOpenCount = 0
        quickBuyCount = 0
        steadySharesBought = 0
        momentumSharesBought = 0
        floorSharesBought = 0
        holdingStartDates = [:]
        achievementClaimedTiers = []
        profitSells = 0
        lossSells = 0
        saveToAccount()
    }
}
