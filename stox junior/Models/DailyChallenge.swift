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

    // Returns a copy with cash amounts in the description scaled to the given starting balance.
    func scaled(to startingBalance: Double) -> DailyChallenge {
        let ratio = startingBalance / 10_000
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.maximumFractionDigits = 0
        func cash(_ base: Double) -> String { fmt.string(from: NSNumber(value: (base * ratio).rounded())) ?? "$\(Int(base * ratio))" }
        switch id {
        case 2: return DailyChallenge(id: id, description: "Use Quick Buy with a \(cash(1_000)) or greater budget", target: target)
        case 4: return DailyChallenge(id: id, description: "Bring your cash balance up to \(cash(4_000)) today", target: target)
        case 5: return DailyChallenge(id: id, description: "Spend \(cash(2_000)) on stocks today", target: target)
        case 7: return DailyChallenge(id: id, description: "Bring your cash balance down to \(cash(6_000)) today", target: target)
        default: return self
        }
    }

    // Deterministic per-day selection — changes every midnight, same for all sessions on the same day.
    static func forToday(startingBalance: Double = 10_000) -> DailyChallenge {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let seed = (c.year ?? 2026) * 400 + (c.month ?? 1) * 31 + (c.day ?? 1)
        return all[abs(seed) % all.count].scaled(to: startingBalance)
    }

    static var todayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
