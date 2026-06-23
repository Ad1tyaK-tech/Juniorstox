import SwiftUI
import Charts

struct StockAnalysisView: View {

    let stock: Stock

    @EnvironmentObject var appState: AppState

    @State private var priceAnalysis: PriceAnalysis? = nil
    @State private var isLoadingAnalysis = false
    @State private var isEstimated = false
    @State private var showBuySheet = false
    @State private var showAdvanced = false

    private let stockService = StockService()

    private var insight: String {
        let c = stock.changePercent
        switch c {
        case 6...:
            return "This stock is ZOOMING today — shooting up way faster than usual! Super exciting, but stocks that move this fast can also drop quickly. Keep your eyes on it!"
        case 3..<6:
            return "Big gains today! This stock is climbing strongly and investors are feeling great about it. It's having one of its best days this week."
        case 1..<3:
            return "Steady and climbing — this stock is quietly having a good day. Think of it like slowly going up an escalator. Not flashy, but heading the right way."
        case -1..<1:
            return "Pretty chill today — barely moving up or down. This stock is just hanging out, waiting for something exciting to happen. Could swing either way soon!"
        case -3..<(-1):
            return "A small dip today, but don't stress. Stocks go down sometimes and bounce right back. This one might just be taking a short break before heading back up."
        case -6..<(-3):
            return "Rough day for this stock. More people are selling than buying, which pushes the price down. It could recover — but worth keeping a close watch."
        default:
            return "Big drop alert! This stock is falling fast today. It might be a risky buy right now, or it could bounce back. Definitely one to watch very carefully."
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // HEADER
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(stock.company)
                            .font(.largeTitle.bold())
                            .foregroundColor(AppColors.textPrimary)
                        Text(stock.symbol)
                            .foregroundColor(AppColors.textSecondary)
                        Text("Current Price: $\(stock.price, specifier: "%.2f")")
                            .foregroundColor(AppColors.gain)
                            .font(.title3.bold())
                    }
                    Spacer()
                    Button {
                        showBuySheet = true
                    } label: {
                        Label("Buy", systemImage: "cart.badge.plus")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(AppColors.accent)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 4)
                }

                HStack(spacing: 4) {
                    Image(systemName: "graduationcap.fill")
                        .font(.caption2)
                    Text("Simulated · No real money involved")
                        .font(.caption2)
                }
                .foregroundColor(AppColors.textTertiary)
                .frame(maxWidth: .infinity)

                Divider()

                insightCard

                chartSection

                if let analysis = priceAnalysis {
                    trendSignalCard(analysis: analysis)
                }

                marketDataCard

                advancedDropdown

                Spacer()
            }
            .padding()
        }
        .background(AppColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background.opacity(0.95), for: .navigationBar)
        .preferredColorScheme(appState.preferredColorScheme)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showBuySheet = true
                } label: {
                    Label("Buy", systemImage: "cart.badge.plus")
                        .foregroundColor(AppColors.accent)
                }
            }
        }
        .sheet(isPresented: $showBuySheet) {
            BuySheet(stock: stock)
                .preferredColorScheme(appState.preferredColorScheme)
        }
        .task {
            isLoadingAnalysis = true
            do {
                priceAnalysis = try await stockService.fetchPriceAnalysis(for: stock.realTicker)
                isEstimated = false
            } catch {
                let synthetic = PriceAnalyzer.syntheticPrices(
                    currentPrice: stock.price,
                    changePercent: stock.changePercent / 3.0,
                    dayHigh: stock.maxima,
                    dayLow: stock.minima,
                    ticker: stock.realTicker
                )
                priceAnalysis = PriceAnalyzer.analyze(closePrices: synthetic)
                isEstimated = true
            }
            isLoadingAnalysis = false
        }
        .onAppear {
            // Auto-advance the tutorial from the "tap a stock" step into the analysis walkthrough.
            guard appState.showTutorial, appState.tutorialStep == tutorialStockTapStep else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    appState.tutorialStep = tutorialStockTapStep + 1
                }
            }
        }
    }

    // MARK: - Insight Card

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Insight")
                .font(.title2.bold())
                .foregroundColor(AppColors.textPrimary)
            Text(insight)
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Chart Section (loads async, always shown)

    @ViewBuilder
    private var chartSection: some View {
        if isLoadingAnalysis && priceAnalysis == nil {
            VStack(spacing: 12) {
                ProgressView().tint(AppColors.accent)
                Text("Crunching 90 days of data…")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(AppColors.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
        } else if let analysis = priceAnalysis {
            chartCard(analysis: analysis)
        }
    }

    // MARK: - Market Data Card

    private var marketDataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Market Data")
                .font(.title2.bold())
                .foregroundColor(AppColors.textPrimary)

            AnalysisRow(
                title: "Trend",
                value: stock.trend,
                info: "Is this stock going up or down today? Increasing means more people are buying it, Decreasing means more people are selling."
            )
            AnalysisRow(
                title: "Slope",
                value: String(format: "%.2f", stock.slopeRate),
                info: "How fast the price is moving. A bigger positive number means it's rising quickly. A negative number means it's dropping. Think of it like the steepness of a hill."
            )
            AnalysisRow(
                title: "Max Price",
                value: String(format: "$%.2f", stock.maxima),
                info: "The highest price this stock hit today — its peak moment. If the current price is close to this, it's near its best point of the day."
            )
            AnalysisRow(
                title: "Min Price",
                value: String(format: "$%.2f", stock.minima),
                info: "The lowest price today — the cheapest it's been. If the current price is close to this, it might be a more affordable entry point."
            )
            AnalysisRow(
                title: "Support Floor",
                value: String(format: "$%.2f", stock.floor),
                info: "Yesterday's closing price. This acts like a baseline — if today's price is above it, the stock is doing better than yesterday!"
            )
            AnalysisRow(
                title: "Daily Change",
                value: String(format: "%.2f%%", stock.changePercent),
                info: "How much the price has changed today compared to yesterday, shown as a percentage. Positive means it grew, negative means it shrank."
            )
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Advanced Dropdown

    private var advancedDropdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showAdvanced.toggle() }
                if showAdvanced { appState.trackAdvancedDropdown(ticker: stock.realTicker) }
            } label: {
                HStack {
                    Label("Advanced Analysis", systemImage: "chart.xyaxis.line")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppColors.textTertiary)
                        .rotationEffect(.degrees(showAdvanced ? 180 : 0))
                }
                .padding(14)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if showAdvanced {
                if isLoadingAnalysis && priceAnalysis == nil {
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            ProgressView().tint(AppColors.accent)
                            Text("Crunching 90 days of data…")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.top, 8)
                } else if let analysis = priceAnalysis {
                    VStack(alignment: .leading, spacing: 16) {
                        statsCard(analysis: analysis)
                        extremaCard(analysis: analysis)
                        glossaryCard
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    // MARK: - Advanced Sub-cards

    @ViewBuilder
    private func chartCard(analysis: PriceAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("90-Day Price Chart")
                        .font(.title2.bold())
                        .foregroundColor(AppColors.textPrimary)
                    Text("Closing price each trading day")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                if isEstimated { estimatedBadge }
            }

            GraphView(
                closePrices: analysis.closePrices,
                trendSignal: analysis.trendSignal
            )
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func trendSignalCard(analysis: PriceAnalysis) -> some View {
        let signalColor: Color = {
            switch analysis.trendSignal {
            case .bullish: return AppColors.gain
            case .bearish:  return AppColors.loss
            case .neutral:  return AppColors.highlight
            }
        }()
        let signalIcon: String = {
            switch analysis.trendSignal {
            case .bullish: return "arrow.up.right.circle.fill"
            case .bearish:  return "arrow.down.right.circle.fill"
            case .neutral:  return "minus.circle.fill"
            }
        }()
        let signalExplainer: String = {
            switch analysis.trendSignal {
            case .bullish:
                return "The closing price is above the 20-day SMA AND the OLS slope is positive — both momentum and trend structure agree the stock is climbing."
            case .bearish:
                return "The closing price is below the 20-day SMA AND the OLS slope is negative — price and trend structure both point downward."
            case .neutral:
                return "The SMA position and slope direction disagree. Markets are indecisive — neither bulls nor bears have clear control."
            }
        }()

        VStack(alignment: .leading, spacing: 14) {
            Text("Trend Signal")
                .font(.title2.bold())
                .foregroundColor(AppColors.textPrimary)

            HStack(spacing: 14) {
                Image(systemName: signalIcon)
                    .font(.system(size: 36))
                    .foregroundColor(signalColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(analysis.trendSignal.rawValue.uppercased())
                        .font(.title3.bold())
                        .foregroundColor(signalColor)
                    Text(signalExplainer)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .background(signalColor.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(signalColor.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(16)
    }

    @ViewBuilder
    private func statsCard(analysis: PriceAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quantitative Stats")
                        .font(.title2.bold())
                        .foregroundColor(AppColors.textPrimary)
                    Text("Calculated from 90 trading days of closes")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                if isEstimated { estimatedBadge }
            }

            AnalysisRow(
                title: "20-Day SMA",
                value: String(format: "$%.2f", analysis.sma),
                info: "Simple Moving Average: the arithmetic mean of the last 20 closing prices. When the current price is above SMA, the stock is in short-term strength. Below SMA signals short-term weakness. Widely used as a baseline by technical analysts."
            )

            AnalysisRow(
                title: "OLS Slope ($/day)",
                value: String(format: "%+.4f", analysis.slope),
                info: "Ordinary Least-Squares regression slope fitted across all 90 closing prices. Tells you the average price change per trading day. A slope of +0.50 means the stock drifts ~$0.50 higher every session on average — but past slope doesn't guarantee future direction."
            )

            AnalysisRow(
                title: "Annualized Volatility",
                value: String(format: "%.2f%%", analysis.volatility * 100),
                info: "σ × √252, where σ is the sample standard deviation of daily log returns over the window. Scaled to annual so it's comparable across assets. <15% is considered low-vol; >40% is high-vol. Higher vol = wider price swings = more risk AND more opportunity."
            )

            // Derived: price vs SMA spread
            let spread = analysis.closePrices.last.map { $0 - analysis.sma } ?? 0
            AnalysisRow(
                title: "Price vs SMA",
                value: String(format: "%+.2f%%", (spread / analysis.sma) * 100),
                info: "How far the latest close sits above or below the 20-day SMA, expressed as a percentage. Traders watch this gap: a very large positive spread (price far above SMA) can signal the stock is overbought; a large negative spread may mean oversold."
            )
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func extremaCard(analysis: PriceAnalysis) -> some View {
        let peakHigh  = analysis.localMaxima.max()
        let troughLow = analysis.localMinima.min()

        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Local Extrema")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.textPrimary)
                Text("Days where price reversed relative to neighbors")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            AnalysisRow(
                title: "Peaks found",
                value: analysis.localMaxima.isEmpty
                    ? "None"
                    : "\(analysis.localMaxima.count)  ·  highest $\(String(format: "%.2f", peakHigh ?? 0))",
                info: "A local peak (local maximum) occurs when a closing price is strictly higher than the day before AND the day after — a mini mountaintop. Peaks are potential resistance levels: price struggled to push past them before reversing.",
                valueColor: AppColors.gain
            )

            AnalysisRow(
                title: "Troughs found",
                value: analysis.localMinima.isEmpty
                    ? "None"
                    : "\(analysis.localMinima.count)  ·  lowest $\(String(format: "%.2f", troughLow ?? 0))",
                info: "A local trough (local minimum) occurs when a closing price is strictly lower than both neighbors — a mini valley. Troughs are potential support levels and can mark buying opportunities if the stock consistently bounces from them.",
                valueColor: AppColors.loss
            )

            if !analysis.localMaxima.isEmpty && !analysis.localMinima.isEmpty,
               let high = peakHigh, let low = troughLow {
                let range = high - low
                HStack {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(AppColors.purple)
                        .font(.caption)
                    Text("Swing range over 90 days: \(String(format: "$%.2f", range))")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }

    private var glossaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Concepts in This Tab", systemImage: "book.closed.fill")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)

            GlossaryRow(term: "SMA", definition: "Simple Moving Average — smooths out daily noise by averaging closes over a window (20 days here). The price crossing above/below it is a classic buy/sell signal.")
            GlossaryRow(term: "OLS Slope", definition: "Ordinary Least-Squares regression — draws the single best-fit straight line through all 90 data points and measures its steepness. More robust than comparing just two points.")
            GlossaryRow(term: "Volatility (σ)", definition: "Standard deviation of daily returns, annualized by multiplying by √252 (trading days/year). The core input to options pricing models like Black-Scholes.")
            GlossaryRow(term: "Support / Resistance", definition: "Price levels where buyers (support) or sellers (resistance) historically show up. Troughs become support; peaks become resistance.")
            GlossaryRow(term: "Bullish / Bearish", definition: "Bull = expecting prices to rise. Bear = expecting prices to fall. Comes from how each animal attacks — bulls thrust upward, bears swipe down.")
        }
        .padding()
        .background(AppColors.indigo.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.indigo.opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(16)
    }

    private var estimatedBadge: some View {
        Text("Estimated")
            .font(.caption2.bold())
            .foregroundColor(AppColors.warning)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(AppColors.warning.opacity(0.12))
            .cornerRadius(5)
    }
}

// MARK: - Glossary Row

private struct GlossaryRow: View {
    let term: String
    let definition: String
    @State private var expanded = false

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(term)
                        .font(.subheadline.bold())
                        .foregroundColor(AppColors.indigo)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary)
                }
                if expanded {
                    Text(definition)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        Divider()
    }
}
