import SwiftUI

extension AppState {

    // MARK: - Persistence

    func loadFrom(_ account: UserAccount) {
        currentAccount = account
        fullName = account.username
        // UserAccount stores dollars (Double) for Supabase compatibility; convert to cents
        cashBalance = Int((account.cashBalance * 100).rounded())
        startingBalance = Int((account.startingBalance * 100).rounded())
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
            netWorthHistory = [NetWorthSnapshot(date: account.createdDate, value: startingBalance)]
        }

        // Rebuild the in-memory stock list from persisted tickers
        ownedStocks = sharesOwned.keys.compactMap { ticker in
            marketStocks.first { $0.realTicker == ticker }
        }

        loadAppliedSplitMultipliers()
        loadChallengeState(from: account)
        loadAchievementsState(from: account)
        loadSettingsState(from: account)
        evaluateChallengeProgress()
        processAppOpen()

        // Fill in any hourly snapshots that were missed while the app was closed
        applyAfkCatchUp()
        Task { await refreshMarket(silent: true) }
    }

    func saveToAccount() {
        guard var account = currentAccount else { return }
        // Convert cents back to dollars for Supabase storage
        account.cashBalance         = Double(cashBalance) / 100.0
        account.startingBalance     = Double(startingBalance) / 100.0
        account.lastSnapshotDate    = lastSnapshotDate
        account.sharesOwnedJSON     = encode(sharesOwned) ?? "{}"
        account.purchasePricesJSON  = encode(purchasePrices) ?? "{}"
        account.netWorthHistoryJSON = encode(netWorthHistory) ?? "[]"
        account.dailyChallengeJSON  = encodeChallengeState()
        account.achievementsJSON    = encodeAchievementsState()
        account.settingsJSON        = encodeSettingsState()
        currentAccount = account
        pendingSaveTask?.cancel()
        let snapshot = account
        pendingSaveTask = Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
                try? await accountService.save(snapshot)
            } catch {}
        }
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

    func applyAfkCatchUp() {
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

    func encode<T: Encodable>(_ value: T) -> String? {
        (try? JSONEncoder().encode(value)).flatMap { String(data: $0, encoding: .utf8) }
    }

    // MARK: - Split multiplier persistence (UserDefaults — device-local)

    func saveAppliedSplitMultipliers() {
        if let data = try? JSONEncoder().encode(appliedSplitMultipliers) {
            UserDefaults.standard.set(data, forKey: "appliedSplitMultipliers")
        }
    }

    func loadAppliedSplitMultipliers() {
        guard let data    = UserDefaults.standard.data(forKey: "appliedSplitMultipliers"),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else { return }
        appliedSplitMultipliers = decoded
    }
}
