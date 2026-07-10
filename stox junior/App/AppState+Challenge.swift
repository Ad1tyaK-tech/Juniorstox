import SwiftUI

extension AppState {

    // MARK: - Challenge State

    private struct ChallengeState: Codable {
        var gems: Int = 0
        var progress: Int = 0
        var claimed: Bool = false
        var dateKey: String = ""
        var netWorthAtDayStart: Int = 0    // cents
        var totalSpentToday: Int = 0       // cents
        var advancedDropdownTickers: [String] = []
    }

    var todayChallenge: DailyChallenge { DailyChallenge.forToday(startingBalance: Double(startingBalance) / 100.0) }
    var isChallengeComplete: Bool { challengeProgress >= todayChallenge.target }

    func loadChallengeState(from account: UserAccount) {
        guard let data = account.dailyChallengeJSON.data(using: .utf8),
              let state = try? JSONDecoder().decode(ChallengeState.self, from: data) else { return }
        gems = state.gems
        challengeProgress = state.progress
        challengeClaimed = state.claimed
        challengeDateKey = state.dateKey
        netWorthAtDayStart = state.netWorthAtDayStart
        totalSpentToday = state.totalSpentToday
        advancedDropdownTickers = Set(state.advancedDropdownTickers)
    }

    func encodeChallengeState() -> String {
        let state = ChallengeState(
            gems: gems,
            progress: challengeProgress,
            claimed: challengeClaimed,
            dateKey: challengeDateKey,
            netWorthAtDayStart: netWorthAtDayStart,
            totalSpentToday: totalSpentToday,
            advancedDropdownTickers: Array(advancedDropdownTickers)
        )
        return encode(state) ?? "{}"
    }

    private func resetIfNewDay() {
        let today = DailyChallenge.todayKey
        guard challengeDateKey != today else { return }
        challengeDateKey = today
        challengeProgress = 0
        challengeClaimed = false
        totalSpentToday = 0
        advancedDropdownTickers = []
        netWorthAtDayStart = currentNetWorth
    }

    // Recomputes progress for challenges driven by current state (not discrete events).
    func evaluateChallengeProgress() {
        resetIfNewDay()
        // ratio: 1.0 at $10,000 default, scales proportionally
        let ratio = Double(startingBalance) / 1_000_000.0
        switch todayChallenge.id {
        case 4: challengeProgress = Double(cashBalance) >= 400_000.0 * ratio ? 1 : 0
        case 7: challengeProgress = Double(cashBalance) <= 600_000.0 * ratio ? 1 : 0
        case 8:
            if netWorthAtDayStart <= 0 { netWorthAtDayStart = currentNetWorth }
            challengeProgress = Double(currentNetWorth) >= Double(netWorthAtDayStart) * 1.02 ? 1 : 0
        default: break
        }
    }

    // cost is in cents
    func trackBuyForChallenge(stock: Stock, shares: Int, cost: Int) {
        resetIfNewDay()
        let sectorOf = Dictionary(uniqueKeysWithValues: stockAliases.map { ($0.realTicker, $0.sector) })
        let sector = sectorOf[stock.realTicker] ?? ""
        let ratio = Double(startingBalance) / 1_000_000.0
        switch todayChallenge.id {
        case 1 where sector == "Big Tech" || sector == "Chip Makers":
            challengeProgress = min(challengeProgress + shares, todayChallenge.target)
        case 5:
            totalSpentToday += cost
            if Double(totalSpentToday) >= 200_000.0 * ratio { challengeProgress = 1 }
        case 6 where sector == "Gaming" || sector == "Shopping":
            challengeProgress = 1
        default: break
        }
        evaluateChallengeProgress()
    }

    func trackSellForChallenge(stock: Stock) {
        resetIfNewDay()
        if todayChallenge.id == 0 {
            let currentChangePercent = marketStocks.first { $0.realTicker == stock.realTicker }?.changePercent ?? stock.changePercent
            if currentChangePercent > 0 { challengeProgress = 1 }
        }
        evaluateChallengeProgress()
    }

    // budget is in dollars (user-entered)
    func trackQuickBuy(budget: Double) {
        resetIfNewDay()
        quickBuyCount += 1
        let ratio = Double(startingBalance) / 1_000_000.0
        switch todayChallenge.id {
        case 2 where budget >= 1_000.0 * ratio: challengeProgress = 1
        case 9: challengeProgress = min(challengeProgress + 1, todayChallenge.target)
        default: break
        }
        evaluateChallengeProgress()
        saveToAccount()
    }

    func trackAdvancedDropdown(ticker: String) {
        resetIfNewDay()
        advancedOpenCount += 1
        if todayChallenge.id == 3 {
            advancedDropdownTickers.insert(ticker)
            challengeProgress = min(advancedDropdownTickers.count, todayChallenge.target)
        }
        evaluateChallengeProgress()
        saveToAccount()
    }

    func claimChallenge() {
        guard isChallengeComplete, !challengeClaimed else { return }
        gems += 5
        challengeClaimed = true
        saveToAccount()
    }
}
