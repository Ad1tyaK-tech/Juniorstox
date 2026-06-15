import Foundation

struct DailyChallenge: Identifiable, Equatable {
    let id: Int
    let description: String
    let target: Int          // units needed to complete (1 = binary, 3/5 = counted)

    static let all: [DailyChallenge] = [
        DailyChallenge(id: 0, description: "Sell a stock that is rising today",                         target: 1),
        DailyChallenge(id: 1, description: "Buy 5 stocks from the technology sector",                   target: 5),
        DailyChallenge(id: 2, description: "Use Quick Buy with a $1,000 or greater budget",             target: 1),
        DailyChallenge(id: 3, description: "Open the advanced analysis for 3 different stocks",         target: 3),
        DailyChallenge(id: 4, description: "Bring your cash balance up to $4,000 today",               target: 1),
        DailyChallenge(id: 5, description: "Spend $2,000 on stocks today",                             target: 1),
        DailyChallenge(id: 6, description: "Buy a stock from the Gaming or Shopping sector",            target: 1),
        DailyChallenge(id: 7, description: "Bring your cash balance down to $6,000 today",             target: 1),
        DailyChallenge(id: 8, description: "Improve your net worth by 2% today",                       target: 1),
        DailyChallenge(id: 9, description: "Use Quick Buy 3 times today",                              target: 3),
    ]

    // Deterministic per-day selection — changes every midnight, same for all sessions on the same day.
    static func forToday() -> DailyChallenge {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let seed = (c.year ?? 2026) * 400 + (c.month ?? 1) * 31 + (c.day ?? 1)
        return all[abs(seed) % all.count]
    }

    static var todayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
