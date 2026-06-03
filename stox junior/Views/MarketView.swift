import SwiftUI

struct MarketView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 18) {

                    HStack {
                        Text("Market")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)

                        Spacer()

                        if appState.isRefreshing {
                            ProgressView()
                                .tint(.white)
                        }
                    }

                    if let error = appState.lastRefreshError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    ForEach(appState.marketStocks) { stock in

                        NavigationLink {
                            StockAnalysisView(stock: stock)
                        } label: {
                            StockCard(stock: stock)
                        }
                    }

                    Text("Prices delayed up to 15 minutes")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
                .padding()
            }
            .background(Color.black)
            .refreshable {
                await appState.refreshMarket()
            }
            .task {
                await appState.refreshMarket()
            }
        }
    }
}
