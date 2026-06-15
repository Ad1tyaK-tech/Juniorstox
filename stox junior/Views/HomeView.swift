import SwiftUI
import Charts

struct HomeView: View {

    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: Int
    @State private var stockToAnalyze: Stock? = nil

    private var topGainer: Stock? {
        appState.marketStocks.max(by: { $0.changePercent < $1.changePercent })
    }

    private var topLoser: Stock? {
        appState.marketStocks.min(by: { $0.changePercent < $1.changePercent })
    }

    private var steadiest: Stock? {
        appState.marketStocks.min(by: { abs($0.changePercent) < abs($1.changePercent) })
    }

    private var history: [NetWorthSnapshot] { appState.netWorthHistory }
    private var currentNetWorth: Double      { appState.currentNetWorth }
    private var startValue: Double           { history.first?.value ?? 10_000 }
    private var change: Double               { currentNetWorth - startValue }
    private var isGain: Bool                 { change >= 0 }
    private var trendColor: Color            { isGain ? AppColors.gain : AppColors.loss }

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 20) {

                VStack(alignment: .leading) {

                    Text("Welcome Back")
                        .foregroundColor(AppColors.textSecondary)

                    Text(appState.fullName)
                        .font(.largeTitle.bold())
                        .foregroundColor(AppColors.textPrimary)

                    Text("Cash Balance: $\(appState.cashBalance, specifier: "%.2f")")
                        .foregroundColor(AppColors.gain)
                }

                dailyChallengeCard

                Button { selectedTab = 2 } label: {
                    miniNetWorthCard
                }
                .buttonStyle(.plain)

                Text("Recent Market Stocks")
                    .foregroundColor(AppColors.textPrimary)
                    .font(.title2.bold())

                if let stock = topGainer {
                    marketHighlight(label: "Top Gainer", icon: "arrow.up.circle.fill", color: AppColors.gain, stock: stock)
                }
                if let stock = topLoser {
                    marketHighlight(label: "Top Loser", icon: "arrow.down.circle.fill", color: AppColors.loss, stock: stock)
                }
                if let stock = steadiest {
                    marketHighlight(label: "Steadiest", icon: "minus.circle.fill", color: AppColors.accent, stock: stock)
                }
            }
            .padding()
        }
        .background(AppColors.background)
        .sheet(item: $stockToAnalyze, onDismiss: { selectedTab = 1 }) { stock in
            NavigationStack {
                StockAnalysisView(stock: stock)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { stockToAnalyze = nil }
                        }
                    }
            }
        }
    }

    // MARK: - Daily Challenge Card

    private var dailyChallengeCard: some View {
        let challenge = appState.todayChallenge
        let complete  = appState.isChallengeComplete
        let claimed   = appState.challengeClaimed

        return VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 6) {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(AppColors.highlight)
                Text("Daily Challenge")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("Reward: 5 💎")
                    .font(.caption.bold())
                    .foregroundColor(AppColors.textSecondary)
            }

            Text(challenge.description)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if challenge.target > 1 {
                HStack(spacing: 10) {
                    ProgressView(value: Double(min(appState.challengeProgress, challenge.target)),
                                 total: Double(challenge.target))
                        .tint(complete ? AppColors.gain : AppColors.accent)
                    Text("\(min(appState.challengeProgress, challenge.target))/\(challenge.target)")
                        .font(.caption.bold())
                        .foregroundColor(AppColors.textSecondary)
                        .monospacedDigit()
                }
            }

            if claimed {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.gain)
                    Text("Claimed! +5 💎")
                        .font(.subheadline.bold())
                        .foregroundColor(AppColors.gain)
                }
            } else {
                Button {
                    appState.claimChallenge()
                } label: {
                    Text(complete ? "Claim  5 💎" : "Complete to Claim")
                        .font(.subheadline.bold())
                        .foregroundColor(complete ? AppColors.textPrimary : AppColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(complete ? AppColors.highlight : AppColors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .disabled(!complete)
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.highlight.opacity(0.30), lineWidth: 1)
        )
    }

    // MARK: - Mini Net Worth Card

    private var miniNetWorthCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("NET WORTH")
                        .font(.caption.bold())
                        .foregroundColor(AppColors.textSecondary)
                        .tracking(1.2)
                    Text("$\(String(format: "%.2f", currentNetWorth))")
                        .font(.title2.bold())
                        .foregroundColor(AppColors.textPrimary)
                }
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: isGain ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption.bold())
                    Text(String(format: "%+.2f%%", startValue > 0 ? (change / startValue) * 100 : 0))
                        .font(.caption.bold())
                }
                .foregroundColor(trendColor)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)
            }

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
                                colors: [trendColor.opacity(0.18), trendColor.opacity(0.02)],
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
                }
                .chartYScale(domain: chartBounds.min...chartBounds.max)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartLegend(.hidden)
                .frame(height: 70)
                .allowsHitTesting(false)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.surfaceSecondary)
                    .frame(height: 50)
                    .overlay(
                        Text("Chart builds as you trade")
                            .font(.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    )
            }
        }
        .padding(14)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private var chartBounds: (min: Double, max: Double) {
        let vals = history.map(\.value)
        let lo   = vals.min() ?? (startValue - 200)
        let hi   = vals.max() ?? (startValue + 200)
        let pad  = Swift.max((hi - lo) * 0.18, 40)
        return (lo - pad, hi + pad)
    }

    @ViewBuilder
    private func marketHighlight(label: String, icon: String, color: Color, stock: Stock) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption.bold())
                    .foregroundColor(color)
            }
            Button { stockToAnalyze = stock } label: {
                StockCard(stock: stock)
            }
            .buttonStyle(.plain)
        }
    }
}
