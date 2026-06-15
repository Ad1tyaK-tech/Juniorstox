import SwiftUI

struct PortfolioInsightCard: View {

    @EnvironmentObject var appState: AppState
    @State private var roll = 0

    var body: some View {
        let info = insight
        HStack(alignment: .top, spacing: 14) {
            Text(info.icon)
                .font(.system(size: 34))
            VStack(alignment: .leading, spacing: 5) {
                Text(info.title)
                    .font(.subheadline.bold())
                    .foregroundColor(AppColors.textPrimary)
                Text(info.body)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [info.color.opacity(0.18), info.color.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(info.color.opacity(0.22), lineWidth: 1)
        )
        .task(id: appState.netWorthHistory.count) {
            roll = Int.random(in: 0..<1000)
        }
    }

    // MARK: - Message logic

    private var insight: (icon: String, title: String, body: String, color: Color) {
        let owned      = appState.ownedStocks
        let history    = appState.netWorthHistory
        let netWorth   = appState.currentNetWorth
        let startValue = history.first?.value ?? 10_000
        let gain       = netWorth - startValue
        let gainPct    = startValue > 0 ? (gain / startValue) * 100 : 0
        let firstName: String = {
            let first = appState.fullName.components(separatedBy: " ").first ?? ""
            return first.isEmpty ? "there" : first
        }()
        let ownedTickers = Set(owned.map(\.realTicker))

        // New user — no holdings yet
        if owned.isEmpty {
            return (
                "👋",
                "Hey \(firstName)!",
                "You've got $\(String(format: "%.0f", netWorth)) ready to invest. Head to the Market tab and grab your first stock!",
                .blue
            )
        }

        // Big milestone celebrations (checked before anything else)
        if gainPct >= 50 {
            return ("🏆", "Portfolio Legend!", "You've grown your money by \(String(format: "%.1f", gainPct))%! That's seriously impressive, \(firstName).", .yellow)
        }
        if gainPct >= 20 {
            return ("🎉", "Big Gains!", "Up \(String(format: "%.1f", gainPct))% from where you started. You're on fire!", .orange)
        }
        if gainPct >= 10 {
            return ("🚀", "Nice Work!", "Your portfolio grew \(String(format: "%.1f", gainPct))% since you started. Keep it rolling!", .green)
        }

        // Would-have / could-have (~1 in 3 refreshes when a good stock is being missed)
        let risingMissed = appState.marketStocks
            .filter { !ownedTickers.contains($0.realTicker) && $0.changePercent > 1.5 }
            .sorted { $0.changePercent > $1.changePercent }
        if let best = risingMissed.first, roll % 3 == 0 {
            return (
                "🤔",
                "Could've Been...",
                "If you'd bought \(best.company) today, you'd already be up \(String(format: "%.1f", best.changePercent))%. Something to think about next time!",
                .purple
            )
        }

        // Positive gain — rotate encouraging messages
        if gain > 0 {
            let options: [(String, String, String)] = [
                ("📈", "Looking good!", "You're up $\(String(format: "%.2f", gain)) since you started. You're a natural, \(firstName)!"),
                ("💰", "Money maker!", "Your portfolio has grown $\(String(format: "%.2f", gain)). Imagine where you'll be in a year!"),
                ("⭐", "Star investor!", "Up \(String(format: "%.1f", gainPct))% from your starting balance. Nice moves!"),
            ]
            let pick = options[roll % options.count]
            return (pick.0, pick.1, pick.2, .green)
        }

        // Significant loss — nudge toward a rising stock they don't own
        if gain < -100 {
            let rising = appState.marketStocks
                .filter { !ownedTickers.contains($0.realTicker) && $0.changePercent > 0 }
                .sorted { $0.changePercent > $1.changePercent }
            if let pivot = rising.first {
                return ("💡", "Heads Up!", "\(pivot.company) is climbing today. Maybe it's time to mix up your strategy?", .orange)
            }
        }

        // Flat or slight loss — rotate motivational messages
        let options: [(String, String, String)] = [
            ("🤞", "Stay patient!", "The market has rough patches. The best investors keep their cool and wait it out."),
            ("📚", "Did you know?", "Warren Buffett lost half his money twice — and kept going. You've got this, \(firstName)!"),
            ("⏰", "Timing is everything", "Sometimes the best move is to hold. Keep watching the Market tab for opportunities."),
        ]
        let pick = options[roll % options.count]
        return (pick.0, pick.1, pick.2, .gray)
    }
}
