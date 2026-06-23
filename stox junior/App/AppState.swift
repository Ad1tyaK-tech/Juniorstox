import SwiftUI
import SwiftData
import Combine

struct NetWorthSnapshot: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let value: Double

    // id is ephemeral (not persisted); date + value are the real data
    enum CodingKeys: CodingKey { case date, value }
}

@MainActor
class AppState: ObservableObject {

    @Published var authState: AuthState = .welcome

    @Published var cashBalance: Double = 10_000
    @Published var fullName: String = ""
    @Published var profileImage: UIImage? = nil

    @Published var marketStocks: [Stock] = sampleStocks
    @Published var ownedStocks: [Stock] = []

    @Published var sharesOwned: [String: Int] = [:]
    @Published var purchasePrices: [String: Double] = [:]

    @Published var netWorthHistory: [NetWorthSnapshot] = []

    @Published var isRefreshing: Bool = false
    @Published var lastRefreshError: String? = nil

    // MARK: - Daily Challenge & Gems

    @Published var gems: Int = 0
    @Published var challengeProgress: Int = 0
    @Published var challengeClaimed: Bool = false

    var todayChallenge: DailyChallenge { DailyChallenge.forToday() }
    var isChallengeComplete: Bool { challengeProgress >= todayChallenge.target }

    private var challengeDateKey: String = ""
    private var netWorthAtDayStart: Double = 0
    private var totalSpentToday: Double = 0
    private var advancedDropdownTickers: Set<String> = []

    // MARK: - Achievement Tracking

    @Published var allTimeOwnedTickers: Set<String> = []
    @Published var maxSharesInOneTicker: Int = 0
    @Published var volatileSharesBought: Int = 0
    @Published var advancedOpenCount: Int = 0
    @Published var quickBuyCount: Int = 0
    @Published var steadySharesBought: Int = 0
    @Published var momentumSharesBought: Int = 0
    @Published var floorSharesBought: Int = 0
    @Published private var achievementClaimedTiers: Set<String> = []

    // MARK: - Streak

    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    private var loginTimestamps: [Double] = []   // Unix time; pruned to 100 days for Market Addict
    private var lastLoginDateKey: String = ""    // "yyyy-MM-dd" of the last processed open

    // MARK: - Tutorial
    @Published var showTutorial: Bool = false
    @Published var tutorialStep: Int = 0

    // MARK: - Settings
    @Published var selectedAvatarId: String = ""
    @Published var ownedAvatarIds: Set<String> = []
    @Published var hapticsDisabled: Bool = false
    @Published var blockCellularData: Bool = false
    @Published var linkedEmail: String = ""
    @Published var colorSchemePref: String = "light"

    var preferredColorScheme: ColorScheme? {
        switch colorSchemePref {
        case "dark":   return .dark
        case "system": return nil
        default:       return .light
        }
    }

    // SwiftData — set after login, nil when logged out
    var modelContext: ModelContext?
    var currentAccount: UserAccount?
    var lastSnapshotDate: Date = .now

    private let stockService = StockService()

    init() {
        netWorthHistory = [NetWorthSnapshot(date: .now, value: cashBalance)]
        Task {
            while true {
                try? await Task.sleep(nanoseconds: 3_600_000_000_000) // 1 hr
                await refreshMarket()
                snapshotNetWorth()
            }
        }
    }

    // MARK: - Persistence

    /// Populate AppState from a saved account and kick off AFK catch-up.
    func loadFrom(_ account: UserAccount, context: ModelContext) {
        currentAccount = account
        modelContext = context
        fullName = account.username
        cashBalance = account.cashBalance
        lastSnapshotDate = account.lastSnapshotDate

        if let data = account.sharesOwnedJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            sharesOwned = decoded
        }
        if let data = account.purchasePricesJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            purchasePrices = decoded
        }
        if let data = account.netWorthHistoryJSON.data(using: .utf8),
           let history = try? JSONDecoder().decode([NetWorthSnapshot].self, from: data),
           !history.isEmpty {
            netWorthHistory = history
        } else {
            netWorthHistory = [NetWorthSnapshot(date: account.createdDate, value: 10_000)]
        }

        // Rebuild the in-memory stock list from persisted tickers
        ownedStocks = sharesOwned.keys.compactMap { ticker in
            marketStocks.first { $0.realTicker == ticker }
        }

        loadChallengeState(from: account)
        loadAchievementsState(from: account)
        loadSettingsState(from: account)
        evaluateChallengeProgress()
        processAppOpen()

        // Fill in any hourly snapshots that were missed while the app was closed
        applyAfkCatchUp()
    }

    /// Write current state back to the SwiftData model and persist.
    func saveToAccount() {
        guard let account = currentAccount, let ctx = modelContext else { return }
        account.cashBalance = cashBalance
        account.lastSnapshotDate = lastSnapshotDate
        account.sharesOwnedJSON = encode(sharesOwned) ?? "{}"
        account.purchasePricesJSON = encode(purchasePrices) ?? "{}"
        account.netWorthHistoryJSON = encode(netWorthHistory) ?? "[]"
        account.dailyChallengeJSON = encodeChallengeState()
        account.achievementsJSON = encodeAchievementsState()
        account.settingsJSON = encodeSettingsState()
        try? ctx.save()
    }

    /// Called from scenePhase .active — fills missed hourly slots and records the open when logged in.
    func catchUpSnapshots() {
        guard authState == .loggedIn else { return }
        processAppOpen()
        applyAfkCatchUp()
    }

    /// Reset all state and return to the welcome screen.
    func logout() {
        saveToAccount()
        currentAccount = nil
        modelContext = nil
        fullName = ""
        cashBalance = 10_000
        ownedStocks = []
        sharesOwned = [:]
        purchasePrices = [:]
        netWorthHistory = [NetWorthSnapshot(date: .now, value: 10_000)]
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
        achievementClaimedTiers = []
        currentStreak = 0
        longestStreak = 0
        loginTimestamps = []
        lastLoginDateKey = ""
        selectedAvatarId = ""
        ownedAvatarIds = []
        hapticsDisabled = false
        blockCellularData = false
        linkedEmail = ""
        colorSchemePref = "light"
        HapticsManager.isDisabled = false
        SoundManager.isDisabled = false
        showTutorial = false
        tutorialStep = 0
        authState = .welcome
    }

    // MARK: - Net Worth

    var currentNetWorth: Double {
        let equity = ownedStocks.reduce(0.0) { sum, stock in
            let price = marketStocks.first { $0.realTicker == stock.realTicker }?.price ?? stock.price
            return sum + price * Double(sharesOwned[stock.realTicker, default: 0])
        }
        return cashBalance + equity
    }

    func snapshotNetWorth() {
        netWorthHistory.append(NetWorthSnapshot(date: .now, value: currentNetWorth))
        if netWorthHistory.count > 168 {
            netWorthHistory.removeFirst(netWorthHistory.count - 168)
        }
        lastSnapshotDate = .now
        evaluateChallengeProgress()
        saveToAccount()
    }

    // MARK: - Trading

    @discardableResult
    func buyStock(_ stock: Stock, shares: Int) -> Bool {
        let cost = stock.price * Double(shares)
        guard cost <= cashBalance else { return false }
        cashBalance -= cost

        let existing = sharesOwned[stock.realTicker, default: 0]
        let existingAvg = purchasePrices[stock.realTicker] ?? stock.price
        let newTotal = existing + shares
        purchasePrices[stock.realTicker] = (existingAvg * Double(existing) + stock.price * Double(shares)) / Double(newTotal)
        sharesOwned[stock.realTicker] = newTotal

        if !ownedStocks.contains(where: { $0.realTicker == stock.realTicker }) {
            ownedStocks.append(stock)
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
        cashBalance += stock.price * Double(shares)
        let remaining = (sharesOwned[stock.realTicker] ?? 0) - shares
        if remaining <= 0 {
            sharesOwned.removeValue(forKey: stock.realTicker)
            purchasePrices.removeValue(forKey: stock.realTicker)
            ownedStocks.removeAll { $0.realTicker == stock.realTicker }
        } else {
            sharesOwned[stock.realTicker] = remaining
        }
        snapshotNetWorth()
        trackSellForChallenge(stock: stock)
    }

    // MARK: - Market Refresh

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
            evaluateChallengeProgress()
            saveToAccount()
        } else {
            marketStocks = fetched
            lastRefreshError = nil
            snapshotNetWorth()
        }
        isRefreshing = false
    }

    // MARK: - Daily Challenge Tracking

    private struct ChallengeState: Codable {
        var gems: Int = 0
        var progress: Int = 0
        var claimed: Bool = false
        var dateKey: String = ""
        var netWorthAtDayStart: Double = 0
        var totalSpentToday: Double = 0
        var advancedDropdownTickers: [String] = []
    }

    private func loadChallengeState(from account: UserAccount) {
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

    private func encodeChallengeState() -> String {
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
        switch todayChallenge.id {
        case 4: challengeProgress = cashBalance >= 4_000 ? 1 : 0
        case 7: challengeProgress = cashBalance <= 6_000 ? 1 : 0
        case 8:
            if netWorthAtDayStart <= 0 { netWorthAtDayStart = currentNetWorth }
            challengeProgress = currentNetWorth >= netWorthAtDayStart * 1.02 ? 1 : 0
        default: break
        }
    }

    private func trackBuyForChallenge(stock: Stock, shares: Int, cost: Double) {
        resetIfNewDay()
        let sectorOf = Dictionary(uniqueKeysWithValues: stockAliases.map { ($0.realTicker, $0.sector) })
        let sector = sectorOf[stock.realTicker] ?? ""
        switch todayChallenge.id {
        case 1 where sector == "Big Tech" || sector == "Chip Makers":
            challengeProgress = min(challengeProgress + shares, todayChallenge.target)
        case 5:
            totalSpentToday += cost
            if totalSpentToday >= 2_000 { challengeProgress = 1 }
        case 6 where sector == "Gaming" || sector == "Shopping":
            challengeProgress = 1
        default: break
        }
        evaluateChallengeProgress()
    }

    private func trackSellForChallenge(stock: Stock) {
        resetIfNewDay()
        if todayChallenge.id == 0 {
            let currentChangePercent = marketStocks.first { $0.realTicker == stock.realTicker }?.changePercent ?? stock.changePercent
            if currentChangePercent > 0 { challengeProgress = 1 }
        }
        evaluateChallengeProgress()
    }

    func trackQuickBuy(budget: Double) {
        resetIfNewDay()
        quickBuyCount += 1
        switch todayChallenge.id {
        case 2 where budget >= 1_000: challengeProgress = 1
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

    // MARK: - Achievements

    private struct AchievementsState: Codable {
        var allTimeOwnedTickers: [String] = []
        var maxSharesInOneTicker: Int = 0
        var volatileSharesBought: Int = 0
        var advancedOpenCount: Int = 0
        var quickBuyCount: Int = 0
        var steadySharesBought: Int = 0
        var momentumSharesBought: Int = 0
        var floorSharesBought: Int = 0
        var claimedTiers: [String] = []
        var currentStreak: Int = 0
        var longestStreak: Int = 0
        var lastLoginDateKey: String = ""
        var loginTimestamps: [Double] = []
    }

    private func loadAchievementsState(from account: UserAccount) {
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
        achievementClaimedTiers = Set(state.claimedTiers)
        currentStreak    = state.currentStreak
        longestStreak    = state.longestStreak
        lastLoginDateKey = state.lastLoginDateKey
        loginTimestamps  = state.loginTimestamps
    }

    private func encodeAchievementsState() -> String {
        let state = AchievementsState(
            allTimeOwnedTickers:  Array(allTimeOwnedTickers),
            maxSharesInOneTicker: maxSharesInOneTicker,
            volatileSharesBought: volatileSharesBought,
            advancedOpenCount:    advancedOpenCount,
            quickBuyCount:        quickBuyCount,
            steadySharesBought:   steadySharesBought,
            momentumSharesBought: momentumSharesBought,
            floorSharesBought:    floorSharesBought,
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
        case "marketAddict":
            // Progress bar shows count in the active tier's rolling window
            let activeTier = AchievementTier.allCases.first { !isTierClaimed(id: "marketAddict", tier: $0) } ?? .platinum
            let (_, windowDays) = marketAddictRequirements(activeTier)
            let cutoff = Date.now.timeIntervalSince1970 - Double(windowDays) * 86400
            return loginTimestamps.filter { $0 >= cutoff }.count
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
    private func processAppOpen() {
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

        // Flat 1 gem per day for any active streak (streak ≥ 2)
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

    // MARK: - Private Helpers

    /// Backfills one snapshot per missed hour (up to 168) using current net worth.
    private func applyAfkCatchUp() {
        let elapsed = Date.now.timeIntervalSince(lastSnapshotDate)
        let missedHours = min(Int(elapsed / 3600), 168)
        guard missedHours > 0 else { return }

        for i in 1...missedHours {
            let snapDate = lastSnapshotDate.addingTimeInterval(Double(i) * 3600)
            netWorthHistory.append(NetWorthSnapshot(date: snapDate, value: currentNetWorth))
        }
        if netWorthHistory.count > 168 {
            netWorthHistory.removeFirst(netWorthHistory.count - 168)
        }
        lastSnapshotDate = .now
        saveToAccount()
    }

    private func encode<T: Encodable>(_ value: T) -> String? {
        (try? JSONEncoder().encode(value)).flatMap { String(data: $0, encoding: .utf8) }
    }

    // MARK: - Settings Persistence

    private struct SettingsState: Codable {
        var selectedAvatarId: String = ""
        var ownedAvatarIds: [String] = []
        var hapticsDisabled: Bool = false
        var blockCellularData: Bool = false
        var linkedEmail: String = ""
        var colorSchemePref: String = "light"
    }

    private func loadSettingsState(from account: UserAccount) {
        guard let data = account.settingsJSON.data(using: .utf8),
              let state = try? JSONDecoder().decode(SettingsState.self, from: data) else { return }
        selectedAvatarId  = state.selectedAvatarId
        ownedAvatarIds    = Set(state.ownedAvatarIds)
        hapticsDisabled   = state.hapticsDisabled
        blockCellularData = state.blockCellularData
        linkedEmail       = state.linkedEmail
        colorSchemePref   = state.colorSchemePref
        HapticsManager.isDisabled = state.hapticsDisabled
        SoundManager.isDisabled = state.hapticsDisabled
    }

    private func encodeSettingsState() -> String {
        let state = SettingsState(
            selectedAvatarId:  selectedAvatarId,
            ownedAvatarIds:    Array(ownedAvatarIds),
            hapticsDisabled:   hapticsDisabled,
            blockCellularData: blockCellularData,
            linkedEmail:       linkedEmail,
            colorSchemePref:   colorSchemePref
        )
        return encode(state) ?? "{}"
    }

    // MARK: - Avatar

    func unlockAvatar(_ id: String) {
        guard let item = AvatarItem.all.first(where: { $0.id == id }) else { return }
        guard gems >= item.category.gemCost, !ownedAvatarIds.contains(id) else { return }
        gems -= item.category.gemCost
        ownedAvatarIds.insert(id)
        saveToAccount()
    }

    func setHapticsDisabled(_ disabled: Bool) {
        hapticsDisabled = disabled
        HapticsManager.isDisabled = disabled
        SoundManager.isDisabled = disabled
        saveToAccount()
    }

    // MARK: - Portfolio Reset

    func resetPortfolio(startingBalance: Double) {
        cashBalance = startingBalance
        sharesOwned = [:]
        purchasePrices = [:]
        ownedStocks = []
        netWorthHistory = [NetWorthSnapshot(date: .now, value: startingBalance)]
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
        achievementClaimedTiers = []
        saveToAccount()
    }

    // MARK: - Account Deletion

    func deleteAccount() {
        guard let account = currentAccount, let ctx = modelContext else { return }
        currentAccount = nil  // prevent saveToAccount() inside logout() from writing to deleted model
        ctx.delete(account)
        try? ctx.save()
        logout()
    }
}
