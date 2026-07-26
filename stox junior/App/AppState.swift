import SwiftUI
import Combine

struct NetWorthSnapshot: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let value: Int  // cents

    var valueDollars: Double { Double(value) / 100.0 }

    // id is ephemeral (not persisted); date + value are the real data
    enum CodingKeys: CodingKey { case date, value }

    init(date: Date, value: Int) {
        self.date = date
        self.value = value
    }
}

@MainActor
class AppState: ObservableObject {

    // MARK: - Auth
    @Published var authState: AuthState = UserDefaults.standard.string(forKey: "session.username") != nil ? .loading : .welcome

    // MARK: - Portfolio
    @Published var cashBalance: Int = 1_000_000      // cents
    @Published var startingBalance: Int = 1_000_000  // cents
    @Published var fullName: String = ""
    @Published var profileImage: UIImage? = nil
    @Published var marketStocks: [Stock] = sampleStocks
    @Published var ownedStocks: [Stock] = []
    @Published var sharesOwned: [String: Int] = [:]
    @Published var purchasePrices: [String: Double] = [:]
    @Published var netWorthHistory: [NetWorthSnapshot] = []
    @Published var isRefreshing: Bool = false
    @Published var appliedSplitMultipliers: [String: Int] = [:]

    // MARK: - Daily Challenge & Gems
    @Published var gems: Int = 0
    @Published var challengeProgress: Int = 0
    @Published var challengeClaimed: Bool = false
    var challengeDateKey: String = ""
    var netWorthAtDayStart: Int = 0   // cents
    var totalSpentToday: Int = 0      // cents
    var advancedDropdownTickers: Set<String> = []

    // MARK: - Achievement Tracking
    @Published var profitSells: Int = 0
    @Published var lossSells: Int = 0
    @Published var allTimeOwnedTickers: Set<String> = []
    @Published var maxSharesInOneTicker: Int = 0
    @Published var volatileSharesBought: Int = 0
    @Published var advancedOpenCount: Int = 0
    @Published var quickBuyCount: Int = 0
    @Published var steadySharesBought: Int = 0
    @Published var momentumSharesBought: Int = 0
    @Published var floorSharesBought: Int = 0
    @Published var holdingStartDates: [String: Date] = [:]
    @Published var achievementClaimedTiers: Set<String> = []

    // MARK: - Streak
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    var loginTimestamps: [Double] = []   // Unix time; pruned to 100 days for Market Addict
    var lastLoginDateKey: String = ""    // "yyyy-MM-dd" of the last processed open

    // MARK: - Tutorial
    @Published var showTutorial: Bool = false
    @Published var tutorialStep: Int = 0

    // MARK: - Settings
    @Published var selectedAvatarId: String = ""
    @Published var ownedAvatarIds: Set<String> = []
    @Published var hapticsDisabled: Bool = false
    @Published var blockCellularData: Bool = false {
        didSet { stockService = StockService(allowsCellularAccess: !blockCellularData) }
    }
    @Published var linkedEmail: String = ""
    @Published var colorSchemePref: String = "light"

    // MARK: - Shared state
    var pendingSaveTask: Task<Void, Never>? = nil
    var currentAccount: UserAccount?
    var lastSnapshotDate: Date = .now

    let accountService = AccountService(url: Secrets.supabaseURL, anonKey: Secrets.supabaseAnonKey)
    let marketService  = MarketService()
    var stockService = StockService()

    init() {
        netWorthHistory = [NetWorthSnapshot(date: .now, value: cashBalance)]
        Task { await restoreSessionIfNeeded() }
        Task {
            while true {
                try? await Task.sleep(nanoseconds: 3_600_000_000_000) // 1 hr
                await refreshMarket()
                snapshotNetWorth()
            }
        }
    }

    func restoreSessionIfNeeded() async {
        guard let username = UserDefaults.standard.string(forKey: "session.username") else { return }
        do {
            let account = try await accountService.fetchAccount(username: username)
            loadFrom(account)
            authState = .loggedIn
        } catch {
            // Network down or account deleted — clear the stale session and go to welcome
            UserDefaults.standard.removeObject(forKey: "session.username")
            authState = .welcome
        }
    }
}
