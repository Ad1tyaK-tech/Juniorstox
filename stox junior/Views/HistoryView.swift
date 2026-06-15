import SwiftUI
import Charts

struct PortfolioHistoryView: View {

    @EnvironmentObject var appState: AppState

    private var history: [NetWorthSnapshot]  { appState.netWorthHistory }
    private var startValue: Double           { history.first?.value ?? 10_000 }
    private var currentValue: Double         { appState.currentNetWorth }
    private var change: Double               { currentValue - startValue }
    private var changePercent: Double        { startValue > 0 ? (change / startValue) * 100 : 0 }
    private var isGain: Bool                 { change >= 0 }
    private var trendColor: Color            { isGain ? AppColors.gain : AppColors.loss }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            netWorthHeader
            chartSection
            if !appState.ownedStocks.isEmpty {
                holdingsSection
            }
        }
        .padding(18)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Net Worth Header

    private var netWorthHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NET WORTH")
                .font(.caption.bold())
                .foregroundColor(AppColors.textSecondary)
                .tracking(1.2)

            Text("$\(String(format: "%.2f", currentValue))")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            HStack(spacing: 5) {
                Image(systemName: isGain ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption.bold())
                let sign = isGain ? "+" : "-"
                Text("\(sign)$\(String(format: "%.2f", abs(change))) (\(String(format: "%+.2f", changePercent))%) since start")
                    .font(.caption.bold())
            }
            .foregroundColor(trendColor)
        }
    }

    // MARK: - Chart

    @ViewBuilder
    private var chartSection: some View {
        if history.count >= 2 {
            Chart {
                ForEach(history) { snap in
                    AreaMark(
                        x: .value("Time", snap.date),
                        yStart: .value("Base", chartBounds.min),
                        yEnd: .value("Value", snap.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [trendColor.opacity(0.20), trendColor.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                }
                ForEach(history) { snap in
                    LineMark(
                        x: .value("Time", snap.date),
                        y: .value("Net Worth", snap.value)
                    )
                    .foregroundStyle(trendColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
                // Starting balance dashed reference
                RuleMark(y: .value("Start", startValue))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.30))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Start $\(Int(startValue))")
                            .font(.caption2)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.trailing, 4)
                    }
            }
            .chartYScale(domain: chartBounds.min...chartBounds.max)
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(AppColors.divider)
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, style: .time)
                                .font(.caption2)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(AppColors.divider)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("$\(Int(v))")
                                .font(.caption2)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
            .frame(height: 180)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.surfaceSecondary)
                VStack(spacing: 10) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(AppColors.textTertiary)
                    Text("Your net worth chart will fill in as you trade and prices update hourly.")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .frame(height: 130)
        }
    }

    // MARK: - Holdings Breakdown

    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Rectangle()
                .fill(AppColors.divider)
                .frame(height: 1)

            Text("HOLDINGS")
                .font(.caption.bold())
                .foregroundColor(AppColors.textSecondary)
                .tracking(1.2)

            VStack(spacing: 0) {
                ForEach(Array(appState.ownedStocks.enumerated()), id: \.element.id) { idx, stock in
                    holdingRow(for: stock)
                    if idx < appState.ownedStocks.count - 1 {
                        Divider().padding(.vertical, 6)
                    }
                }
            }

            // Summary totals
            let totals = holdingsTotals
            if totals.cost > 0 {
                Rectangle().fill(AppColors.divider).frame(height: 1)
                HStack {
                    Text("Total invested")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(String(format: "%.2f", totals.value))")
                            .font(.subheadline.bold())
                            .foregroundColor(AppColors.textPrimary)
                        let pnl = totals.value - totals.cost
                        let pnlSign = pnl >= 0 ? "+" : "-"
                        Text("\(pnlSign)$\(String(format: "%.2f", abs(pnl)))")
                            .font(.caption.bold())
                            .foregroundColor(pnl >= 0 ? AppColors.gain : AppColors.loss)
                    }
                }
            }
        }
    }

    private func holdingRow(for stock: Stock) -> some View {
        let shares     = appState.sharesOwned[stock.realTicker] ?? 0
        let buyPrice   = appState.purchasePrices[stock.realTicker] ?? stock.price
        let nowPrice   = appState.marketStocks.first { $0.realTicker == stock.realTicker }?.price ?? stock.price
        let totalValue = nowPrice * Double(shares)
        let totalCost  = buyPrice * Double(shares)
        let pnl        = totalValue - totalCost
        let pnlPct     = totalCost > 0 ? (pnl / totalCost) * 100 : 0
        let pnlColor: Color = pnl >= 0 ? AppColors.gain : AppColors.loss

        return VStack(spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(stock.company)
                        .font(.subheadline.bold())
                        .foregroundColor(AppColors.textPrimary)
                    Text("\(stock.symbol) · \(shares) share\(shares == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(String(format: "%.2f", totalValue))")
                        .font(.subheadline.bold())
                        .foregroundColor(AppColors.textPrimary)
                    let pnlSign = pnl >= 0 ? "+" : "-"
                    Text("\(pnlSign)$\(String(format: "%.2f", abs(pnl))) (\(String(format: "%+.1f", pnlPct))%)")
                        .font(.caption.bold())
                        .foregroundColor(pnlColor)
                }
            }
            HStack {
                Label("Avg $\(String(format: "%.2f", buyPrice))", systemImage: "tag")
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Label("Now $\(String(format: "%.2f", nowPrice))", systemImage: "clock")
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    // MARK: - Helpers

    private var holdingsTotals: (cost: Double, value: Double) {
        appState.ownedStocks.reduce((0.0, 0.0)) { acc, stock in
            let shares   = Double(appState.sharesOwned[stock.realTicker] ?? 0)
            let buyPrice = appState.purchasePrices[stock.realTicker] ?? stock.price
            let nowPrice = appState.marketStocks.first { $0.realTicker == stock.realTicker }?.price ?? stock.price
            return (acc.0 + buyPrice * shares, acc.1 + nowPrice * shares)
        }
    }

    // Y-axis domain with padding so the line never touches the edges
    private var chartBounds: (min: Double, max: Double) {
        let vals = history.map(\.value)
        let lo   = vals.min() ?? (startValue - 500)
        let hi   = vals.max() ?? (startValue + 500)
        let pad  = Swift.max((hi - lo) * 0.18, 60)
        return (lo - pad, hi + pad)
    }
}
