import Foundation

enum AchievementTier: Int, CaseIterable, Codable {
    case amateur  = 0
    case bronze   = 1
    case silver   = 2
    case gold     = 3
    case platinum = 4

    var label: String {
        switch self {
        case .amateur:  return "Amateur"
        case .bronze:   return "Bronze"
        case .silver:   return "Silver"
        case .gold:     return "Gold"
        case .platinum: return "Platinum"
        }
    }

    var gemReward: Int {
        switch self {
        case .amateur:  return 10
        case .bronze:   return 30
        case .silver:   return 60
        case .gold:     return 100
        case .platinum: return 200
        }
    }

    // SF Symbol used for the tier dot when it's the active (in-progress) tier
    var sfBadge: String {
        switch self {
        case .amateur:  return "1.circle.fill"
        case .bronze:   return "2.circle.fill"
        case .silver:   return "3.circle.fill"
        case .gold:     return "4.circle.fill"
        case .platinum: return "5.circle.fill"
        }
    }
}

struct AchievementDef: Identifiable {
    let id: String
    let title: String
    let icon: String
    let thresholds: [Int]   // index = AchievementTier.rawValue

    func threshold(for tier: AchievementTier) -> Int { thresholds[tier.rawValue] }

    func description(for tier: AchievementTier) -> String {
        let n = thresholds[tier.rawValue]
        switch id {
        case "diversePortfolio": return "Buy \(n)+ shares in 8+ different stocks"
        case "investor":         return "Hold \(n)+ shares in one stock at once"
        case "gambler":          return "Buy \(n)+ shares in volatile stocks (±2% today)"
        case "intellectual":     return "Open the advanced view \(n)+ times"
        case "spontaneous":      return "Use Quick Buy \(n)+ times"
        case "safeInvestor":     return "Buy \(n)+ shares of steady stocks"
        case "momentumBuyer":    return "Buy \(n)+ shares in fast-rising stocks (+2% today)"
        case "bargainer":        return "Buy \(n)+ shares near a stock's floor price"
        case "marketAddict":
            let windows = [5, 7, 15, 25, 100]
            return "Open the app \(n)× within \(windows[tier.rawValue]) days"
        default:                 return ""
        }
    }

    static let all: [AchievementDef] = [
        .init(id: "diversePortfolio", title: "Diverse Portfolio",
              icon: "chart.pie.fill",
              thresholds: [5, 20, 50, 100, 250]),
        .init(id: "investor",         title: "Investor",
              icon: "dollarsign.circle.fill",
              thresholds: [5, 20, 50, 100, 250]),
        .init(id: "gambler",          title: "Gambler",
              icon: "dice.fill",
              thresholds: [3, 10, 20, 50, 100]),
        .init(id: "intellectual",     title: "Intellectual",
              icon: "brain.head.profile",
              thresholds: [20, 50, 200, 500, 750]),
        .init(id: "spontaneous",      title: "Spontaneous",
              icon: "bolt.circle.fill",
              thresholds: [10, 25, 100, 250, 500]),
        .init(id: "safeInvestor",     title: "Safe Investor",
              icon: "shield.fill",
              thresholds: [5, 20, 50, 100, 250]),
        .init(id: "momentumBuyer",    title: "Momentum Buyer",
              icon: "arrow.up.right.circle.fill",
              thresholds: [5, 20, 50, 100, 250]),
        .init(id: "bargainer",        title: "Bargainer",
              icon: "tag.fill",
              thresholds: [5, 20, 50, 100, 250]),
        .init(id: "marketAddict",     title: "Market Addict",
              icon: "flame.fill",
              thresholds: [15, 30, 50, 100, 500]),
    ]
}
