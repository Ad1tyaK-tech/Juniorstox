import SwiftUI

private let sectorOrder = ["Big Tech", "Chip Makers", "Shopping", "Cars & Energy", "Money & Crypto", "Gaming"]

private func sectorIcon(_ sector: String) -> String {
    switch sector {
    case "Big Tech":       return "laptopcomputer"
    case "Chip Makers":    return "cpu"
    case "Shopping":       return "bag"
    case "Cars & Energy":  return "car"
    case "Money & Crypto": return "dollarsign.circle"
    case "Gaming":         return "gamecontroller"
    default:               return "chart.bar"
    }
}

struct MarketView: View {

    @EnvironmentObject var appState: AppState
    @State private var stockToBuy: Stock? = nil
    @State private var expandedSectors: Set<String> = Set(sectorOrder)

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 14) {

                    HStack {
                        Text("Market")
                            .font(.largeTitle.bold())
                            .foregroundColor(AppColors.textPrimary)

                        Spacer()

                        if appState.isRefreshing {
                            ProgressView()
                                .tint(AppColors.accent)
                        }
                    }

                    if let error = appState.lastRefreshError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(AppColors.warning)
                    }

                    ForEach(stocksBySector, id: \.sector) { group in
                        SectorSection(
                            sector: group.sector,
                            stocks: group.stocks,
                            isExpanded: expandedSectors.contains(group.sector),
                            onToggle: { toggle(group.sector) },
                            onBuy: { stockToBuy = $0 }
                        )
                    }

                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right")
                            Text("Swipe right on any stock to buy")
                        }
                        .font(.caption2)
                        .foregroundColor(AppColors.textTertiary)
                        Text("Prices delayed up to 15 minutes")
                            .font(.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(AppColors.background)
            .refreshable {
                await appState.refreshMarket()
            }
            .task {
                await appState.refreshMarket()
            }
            .sheet(item: $stockToBuy) { stock in
                BuySheet(stock: stock)
            }
        }
    }

    private var stocksBySector: [(sector: String, stocks: [Stock])] {
        let lookup = Dictionary(uniqueKeysWithValues: stockAliases.map { ($0.realTicker, $0.sector) })
        var grouped: [String: [Stock]] = [:]
        for stock in appState.marketStocks {
            let sec = lookup[stock.realTicker] ?? "Other"
            grouped[sec, default: []].append(stock)
        }
        return sectorOrder.compactMap { sec in
            guard let stocks = grouped[sec], !stocks.isEmpty else { return nil }
            return (sector: sec, stocks: stocks)
        }
    }

    private func toggle(_ sector: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedSectors.contains(sector) {
                expandedSectors.remove(sector)
            } else {
                expandedSectors.insert(sector)
            }
        }
    }
}

private struct SectorSection: View {

    let sector: String
    let stocks: [Stock]
    let isExpanded: Bool
    let onToggle: () -> Void
    let onBuy: (Stock) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            Button(action: onToggle) {
                HStack(spacing: 10) {
                    Image(systemName: sectorIcon(sector))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.accent)
                        .frame(width: 24)

                    Text(sector)
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    Text("\(stocks.count) stock\(stocks.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppColors.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(stocks) { stock in
                        NavigationLink {
                            StockAnalysisView(stock: stock)
                        } label: {
                            SwipeRevealCard(
                                actionColor: AppColors.gain,
                                actionIcon: "cart.badge.plus",
                                actionLabel: "Buy",
                                isLeading: true,
                                onAction: { onBuy(stock) }
                            ) {
                                StockCard(stock: stock)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
