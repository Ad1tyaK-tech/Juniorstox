import SwiftUI

extension AppState {

    // MARK: - Achievements State

    private struct AchievementsState: Codable {
        var allTimeOwnedTickers: [String] = []
        var maxSharesInOneTicker: Int = 0
        var volatileSharesBought: Int = 0
        var advancedOpenCount: Int = 0
        var quickBuyCount: Int = 0
        var steadySharesBought: Int = 0
        var momentumSharesBought: Int = 0
        var floorSharesBought: Int = 0
        var holdingStartDates: [String: Double] = [:]
        var profitSells: Int = 0
        var lossSells: Int = 0
        var claimedTiers: [String] = []
        var currentStreak: Int = 0
        var longestStreak: Int = 0
        var lastLoginDateKey: String = ""
        var loginTimestamps: [Double] = []
    }

    func loadAchievementsState(from account: UserAccount) {
        guard let data = account.achievementsJSON.data(using: .utf8),
              let state = try? JSONDecoder().decode(AchievementsState.self, from: data) else { return }
        allTimeOwnedTickers  = Set(state.allTimeOwnedTickers)
        maxSharesInOneTicker = state.maxSharesInOneTicker
        volatileSharesBought = state.volatileSharesBought
        advancedOpenCount    = state.advancedOpenCount
        quickBuyCount        = state.quickBuyCount
        steadySharesBought   = state.steadySharesBought
        momentumSharesBought = state.momentumSharesBought
        floorSharesBought    = state.floorSharesBought
        holdingStartDates    = state.holdingStartDates.mapValues { Date(timeIntervalSince1970: $0) }
        profitSells = state.profitSells
        lossSells   = state.lossSells
        achievementClaimedTiers = Set(state.claimedTiers)
        currentStreak    = state.currentStreak
        longestStreak    = state.longestStreak
        lastLoginDateKey = state.lastLoginDateKey
        loginTimestamps  = state.loginTimestamps
    }

    func encodeAchievementsState() -> String {
        let state = AchievementsState(
            allTimeOwnedTickers:  Array(allTimeOwnedTickers),
            maxSharesInOneTicker: maxSharesInOneTicker,
            volatileSharesBought: volatileSharesBought,
            advancedOpenCount:    advancedOpenCount,
            quickBuyCount:        quickBuyCount,
            steadySharesBought:   steadySharesBought,
            momentumSharesBought: momentumSharesBought,
            floorSharesBought:    floorSharesBought,
            holdingStartDates:    holdingStartDates.mapValues { $0.timeIntervalSince1970 },
            profitSells:          profitSells,
            lossSells:            lossSells,
            claimedTiers:         Array(achievementClaimedTiers),
            currentStreak:        currentStreak,
            longestStreak:        longestStreak,
            lastLoginDateKey:     lastLoginDateKey,
            loginTimestamps:      loginTimestamps
        )
        return encode(state) ?? "{}"
    }

    func achievementProgress(for id: String) -> Int {
        switch id {
        case "diversePortfolio": return allTimeOwnedTickers.count
        case "investor":         return maxSharesInOneTicker
        case "gambler":          return volatileSharesBought
        case "intellectual":     return advancedOpenCount
        case "spontaneous":      return quickBuyCount
        case "safeInvestor":     return steadySharesBought
        case "momentumBuyer":    return momentumSharesBought
        case "bargainer":        return floorSharesBought
        case "tookProfit":       return profitSells
        case "cutLosses":        return lossSells
        case "marketAddict":
            // Progress bar shows count in the active tier's rolling window
            let activeTier = AchievementTier.allCases.first { !isTierClaimed(id: "marketAddict", tier: $0) } ?? .platinum
            let (_, windowDays) = marketAddictRequirements(activeTier)
            let cutoff = Date.now.timeIntervalSince1970 - Double(windowDays) * 86400
            return loginTimestamps.filter { $0 >= cutoff }.count
        case "loyalty":
            // Progress bar shows max shares held in any current position
            return ownedStocks.compactMap { sharesOwned[$0.realTicker] }.max() ?? 0
        default:                 return 0
        }
    }

    // MARK: - Achievement Claiming

    func isTierClaimed(id: String, tier: AchievementTier) -> Bool {
        achievementClaimedTiers.contains("\(id)_\(tier.rawValue)")
    }

    // A tier is claimable when: threshold met, not yet claimed, and previous tier claimed
    // (or it's the Amateur tier which has no prereq).
    // Market Addict uses a rolling window check instead of a single lifetime counter.
    func isTierClaimable(id: String, tier: AchievementTier) -> Bool {
        guard !isTierClaimed(id: id, tier: tier) else { return false }
        let thresholdMet: Bool
        if id == "marketAddict" {
            thresholdMet = marketAddictTierMet(tier)
        } else if id == "loyalty" {
            thresholdMet = loyaltyTierMet(tier)
        } else {
            guard let def = AchievementDef.all.first(where: { $0.id == id }) else { return false }
            thresholdMet = achievementProgress(for: id) >= def.threshold(for: tier)
        }
        guard thresholdMet else { return false }
        if tier == .amateur { return true }
        let prev = AchievementTier(rawValue: tier.rawValue - 1)!
        return isTierClaimed(id: id, tier: prev)
    }

    // True when any achievement tier is ready to be claimed — drives the red dot.
    var hasClaimableAchievements: Bool {
        AchievementDef.all.contains { def in
            AchievementTier.allCases.contains { isTierClaimable(id: def.id, tier: $0) }
        }
    }

    func claimAchievementTier(id: String, tier: AchievementTier) {
        guard isTierClaimable(id: id, tier: tier) else { return }
        achievementClaimedTiers.insert("\(id)_\(tier.rawValue)")
        gems += tier.gemReward
        saveToAccount()
    }

    // MARK: - Streak & Login Tracking

    // Called on every app open (login + foreground). Records a timestamp for Market Addict
    // and advances the streak once per calendar day.
    func processAppOpen() {
        let nowTS = Date.now.timeIntervalSince1970

        // Deduplicate rapid successive calls (e.g. loadFrom + catchUpSnapshots < 60s apart)
        if let last = loginTimestamps.last, nowTS - last < 60 {
            advanceStreakIfNewDay()
            return
        }

        loginTimestamps.append(nowTS)
        // Prune timestamps older than 100 days (max Market Addict window)
        loginTimestamps = loginTimestamps.filter { $0 >= nowTS - 100 * 86400 }

        advanceStreakIfNewDay()
        saveToAccount()
    }

    private func advanceStreakIfNewDay() {
        let today = Self.todayDateKey()
        guard lastLoginDateKey != today else { return }

        if lastLoginDateKey == Self.yesterdayDateKey() {
            currentStreak += 1
        } else {
            currentStreak = 1
        }
        longestStreak    = max(longestStreak, currentStreak)
        lastLoginDateKey = today

        // Flat 1 gem per day for any active streak (streak >= 2)
        if currentStreak >= 2 { gems += 1 }
    }

    private static func todayDateKey() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: .now)
    }

    private static func yesterdayDateKey() -> String {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: cal.date(byAdding: .day, value: -1, to: .now)!)
    }

    // MARK: - Market Addict Helpers

    private func marketAddictRequirements(_ tier: AchievementTier) -> (logins: Int, days: Int) {
        switch tier {
        case .amateur:  return (15,  5)
        case .bronze:   return (30,  7)
        case .silver:   return (50,  15)
        case .gold:     return (100, 25)
        case .platinum: return (500, 100)
        }
    }

    private func marketAddictTierMet(_ tier: AchievementTier) -> Bool {
        let (loginTarget, windowDays) = marketAddictRequirements(tier)
        let cutoff = Date.now.timeIntervalSince1970 - Double(windowDays) * 86400
        return loginTimestamps.filter { $0 >= cutoff }.count >= loginTarget
    }

    // MARK: - Loyalty Helpers

    private func loyaltyRequirements(_ tier: AchievementTier) -> (shares: Int, days: Int) {
        switch tier {
        case .amateur:  return (3,  5)
        case .bronze:   return (10, 15)
        case .silver:   return (15, 30)
        case .gold:     return (30, 100)
        case .platinum: return (50, 250)
        }
    }

    private func loyaltyTierMet(_ tier: AchievementTier) -> Bool {
        let (sharesReq, daysReq) = loyaltyRequirements(tier)
        return holdingStartDates.contains { ticker, startDate in
            let daysHeld = Int(Date.now.timeIntervalSince(startDate) / 86400)
            return (sharesOwned[ticker] ?? 0) >= sharesReq && daysHeld >= daysReq
        }
    }
}
