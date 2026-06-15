import SwiftUI

enum QuickBuyMode: String, CaseIterable {
    case passive  = "Passive"
    case momentum = "Momentum"
    case value    = "Value"

    var icon: String {
        switch self {
        case .passive:  return "leaf.fill"
        case .momentum: return "bolt.fill"
        case .value:    return "tag.fill"
        }
    }

    // Brief description shown in the dropdown and as a card subtitle
    var hint: String {
        switch self {
        case .passive:  return "Steady grower, low swings"
        case .momentum: return "Fastest rising right now"
        case .value:    return "Buy the dip, deep discount"
        }
    }
}

struct PortfolioView: View {

    @EnvironmentObject var appState: AppState
    @State private var stockToSell: Stock? = nil
    @State private var quickBuyBudget: String = "500"
    @State private var quickBuyResult: String? = nil
    @State private var investorMode: QuickBuyMode = .passive

    private struct QuickBuyItem: Identifiable {
        let stock: Stock
        let shares: Int
        var id: String { stock.realTicker }
    }

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 18) {

                Text("Your Portfolio")
                    .font(.largeTitle.bold())
                    .foregroundColor(AppColors.textPrimary)

                Text("Cash: $\(appState.cashBalance, specifier: "%.2f")")
                    .foregroundColor(AppColors.gain)

                if appState.ownedStocks.isEmpty {

                    Text("You don't own any stocks yet.")
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.top, 20)

                } else {

                    ForEach(appState.ownedStocks) { stock in
                        SwipeRevealCard(
                            actionColor: AppColors.loss,
                            actionIcon: "arrow.down.circle",
                            actionLabel: "Sell",
                            isLeading: false,
                            onAction: { stockToSell = stock }
                        ) {
                            StockCard(
                                stock: stock,
                                shares: appState.sharesOwned[stock.realTicker]
                            )
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                        Text("Swipe left on a holding to sell")
                    }
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                PortfolioInsightCard()
                quickBuyCard
                PortfolioHistoryView()
            }
            .padding()
        }
        .background(AppColors.background)
        .sheet(item: $stockToSell) { stock in
            SellSheet(stock: stock)
        }
    }

    // MARK: - Quick Buy Card

    private var quickBuyCard: some View {
        let plan = quickBuyPlan
        return VStack(alignment: .leading, spacing: 12) {

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("QUICK BUY")
                        .font(.caption.bold())
                        .foregroundColor(AppColors.textSecondary)
                        .tracking(1.2)
                    Text(modeSubtitle)
                        .font(.subheadline.bold())
                        .foregroundColor(AppColors.textPrimary)
                }
                Spacer()
                Image(systemName: "bolt.fill")
                    .foregroundColor(AppColors.highlight)
                    .font(.title2)
            }

            // Budget input + investor mode picker side by side
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text("Budget:")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Text("$")
                        .foregroundColor(AppColors.textSecondary)
                    TextField("500", text: $quickBuyBudget)
                        .keyboardType(.decimalPad)
                        .foregroundColor(AppColors.textPrimary)
                }
                .padding(10)
                .background(AppColors.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Mode dropdown — each option shows its own brief hint as the info
                Menu {
                    ForEach(QuickBuyMode.allCases, id: \.self) { mode in
                        Button { investorMode = mode } label: {
                            Label(mode.rawValue + " · " + mode.hint, systemImage: mode.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: investorMode.icon)
                            .font(.caption)
                        Text(investorMode.rawValue)
                            .font(.caption.bold())
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(AppColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            // Active mode hint line
            Text(investorMode.hint)
                .font(.caption2)
                .foregroundColor(AppColors.textSecondary)

            if plan.isEmpty {
                Text(emptyPlanMessage)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                VStack(spacing: 6) {
                    ForEach(plan) { item in
                        let pct = item.stock.changePercent
                        let pctText = (pct >= 0 ? "+" : "") + String(format: "%.2f", pct) + "%"
                        let pctColor = pct >= 0 ? AppColors.gain : AppColors.loss
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.stock.company)
                                    .font(.caption.bold())
                                    .foregroundColor(AppColors.textPrimary)
                                Text(pctText)
                                    .font(.caption2)
                                    .foregroundColor(pctColor)
                            }
                            Spacer()
                            Text("\(item.shares) share\(item.shares == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                            Text("$\(String(format: "%.2f", item.stock.price * Double(item.shares)))")
                                .font(.caption.bold())
                                .foregroundColor(AppColors.textPrimary)
                                .frame(minWidth: 60, alignment: .trailing)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(AppColors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                Button {
                    executeQuickBuy(plan: plan)
                } label: {
                    Text("Buy All! ⚡")
                        .font(.subheadline.bold())
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.highlight)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            if let result = quickBuyResult {
                Text(result)
                    .font(.caption.bold())
                    .foregroundColor(AppColors.gain)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.highlight.opacity(0.30), lineWidth: 1)
        )
        .onChange(of: quickBuyBudget)  { _, _ in quickBuyResult = nil }
        .onChange(of: investorMode)    { _, _ in quickBuyResult = nil }
    }

    private var modeSubtitle: String {
        switch investorMode {
        case .passive:  return "Pick steady growers for your budget"
        case .momentum: return "Spread your budget across rising stocks"
        case .value:    return "Find stocks trading at a discount"
        }
    }

    private var emptyPlanMessage: String {
        guard parsedBudget > 0 else { return "Enter a budget above to see your plan." }
        if parsedBudget > appState.cashBalance {
            return "Budget exceeds your cash balance of $\(String(format: "%.2f", appState.cashBalance))."
        }
        switch investorMode {
        case .passive:  return "No steadily growing stocks match your budget right now."
        case .momentum: return "No rising stocks available right now."
        case .value:    return "No discounted stocks available right now."
        }
    }

    // MARK: - Quick Buy Logic

    private var parsedBudget: Double {
        Double(quickBuyBudget.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var quickBuyPlan: [QuickBuyItem] {
        let budget = min(parsedBudget, appState.cashBalance)
        guard budget > 0 else { return [] }

        let candidates: [Stock]
        switch investorMode {
        case .passive:
            // Positive long-term slope; reward steady slope, penalise today's volatility
            candidates = appState.marketStocks
                .filter { $0.slopeRate > 0 && $0.price <= budget }
                .sorted { passiveScore($0) > passiveScore($1) }
        case .momentum:
            // Rising today with strong trend signal
            candidates = appState.marketStocks
                .filter { $0.changePercent > 0 && $0.price <= budget }
                .sorted { momentumScore($0) > momentumScore($1) }
        case .value:
            // Currently down and closest to its historical floor support level
            candidates = appState.marketStocks
                .filter { $0.changePercent < 0 && $0.price <= budget }
                .sorted { valueScore($0) > valueScore($1) }
        }
        guard !candidates.isEmpty else { return [] }

        var remaining = budget
        var sharesByTicker: [String: Int] = [:]

        // Phase 1: up to 3 shares of each candidate, best score first
        for stock in candidates {
            guard remaining >= stock.price else { continue }
            let affordable = Int(remaining / stock.price)
            let shares = min(3, affordable)
            if shares > 0 {
                sharesByTicker[stock.realTicker] = shares
                remaining -= stock.price * Double(shares)
            }
        }

        // Phase 2: dump leftover budget into the top-scored candidate
        let best = candidates[0]
        if remaining >= best.price {
            let extra = Int(remaining / best.price)
            if extra > 0 {
                sharesByTicker[best.realTicker] = (sharesByTicker[best.realTicker] ?? 0) + extra
            }
        }

        return candidates.compactMap { stock in
            guard let shares = sharesByTicker[stock.realTicker] else { return nil }
            return QuickBuyItem(stock: stock, shares: shares)
        }
    }

    // Steady long-term slope rewarded; amplified daily swings penalised
    private func passiveScore(_ stock: Stock) -> Double {
        stock.slopeRate * 3.0 - abs(stock.changePercent)
    }

    // Today's momentum + trend bonus
    private func momentumScore(_ stock: Stock) -> Double {
        let trendBonus = stock.trend == "Increasing" ? 5.0 : 0.0
        return stock.changePercent * 0.5 + stock.slopeRate * 0.5 + trendBonus
    }

    // Closer to floor support level = better value (deeper discount relative to typical low)
    private func valueScore(_ stock: Stock) -> Double {
        -(stock.price - stock.floor) / max(0.01, stock.price)
    }

    private func executeQuickBuy(plan: [QuickBuyItem]) {
        for item in plan {
            appState.buyStock(item.stock, shares: item.shares)
        }
        appState.trackQuickBuy(budget: parsedBudget)
        let summary = plan.map { "\($0.shares)× \($0.stock.company)" }.joined(separator: ", ")
        withAnimation {
            quickBuyResult = "Bought \(summary)! 🎉"
            quickBuyBudget = ""
        }
    }
}
