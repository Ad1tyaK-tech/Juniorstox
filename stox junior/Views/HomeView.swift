import SwiftUI

struct HomeView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 20) {

                VStack(alignment: .leading) {

                    Text("Welcome Back")
                        .foregroundColor(.gray)

                    Text(appState.fullName)
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("Cash Balance: $\(appState.cashBalance, specifier: "%.2f")")
                        .foregroundColor(.green)
                }

                Text("Recent Market Stocks")
                    .foregroundColor(.white)
                    .font(.title2.bold())

                ForEach(appState.marketStocks.prefix(3)) { stock in
                    StockCard(stock: stock)
                }
            }
            .padding()
        }
        .background(Color.black)
    }
}
// MARK: - MARKET VIEW


//  homeview.swift
//  stox junior
//
//  Created by Aditya Kiran on 5/25/26.
//

