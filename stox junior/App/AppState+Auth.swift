import SwiftUI

extension AppState {

    // MARK: - Supabase Auth helpers (called by auth views)

    func attemptLogin(username: String, password: String) async throws {
        let account = try await accountService.login(username: username, password: password)
        UserDefaults.standard.set(account.username, forKey: "session.username")
        loadFrom(account)
        authState = .loggedIn
    }

    func attemptCreateAccount(username: String, password: String, email: String) async throws {
        if !email.isEmpty, try await accountService.isEmailTaken(email) {
            throw AccountError.emailTaken
        }
        let account = try await accountService.createAccount(username: username, password: password)
        UserDefaults.standard.set(account.username, forKey: "session.username")
        loadFrom(account)
        if !email.isEmpty {
            linkedEmail = email
            saveToAccount()
        }
        authState = .privacyConsent
    }

    /// Called from scenePhase .active — fills missed hourly slots, records the open, and syncs market prices.
    func catchUpSnapshots() {
        guard authState == .loggedIn else { return }
        processAppOpen()
        applyAfkCatchUp()
        Task { await refreshMarket(silent: true) }
    }

    /// Reset all state and return to the welcome screen.
    func logout() {
        UserDefaults.standard.removeObject(forKey: "session.username")
        saveToAccount()
        currentAccount = nil
        fullName = ""
        cashBalance = 1_000_000
        startingBalance = 1_000_000
        ownedStocks = []
        sharesOwned = [:]
        purchasePrices = [:]
        netWorthHistory = [NetWorthSnapshot(date: .now, value: 1_000_000)]
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

    func deleteAccount() {
        guard let account = currentAccount else { return }
        let username = account.username
        currentAccount = nil  // prevent saveToAccount() inside logout() from writing to deleted row
        Task { try? await accountService.delete(username: username) }
        logout()
    }
}
