import SwiftUI

struct PortfolioView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 18) {

                Text("Your Portfolio")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                Text("Cash: $\(appState.cashBalance, specifier: "%.2f")")
                    .foregroundColor(.green)

                if appState.ownedStocks.isEmpty {

                    Text("You don't own any stocks yet.")
                        .foregroundColor(.gray)
                        .padding(.top, 20)

                } else {

                    ForEach(appState.ownedStocks) { stock in
                        StockCard(stock: stock)
                    }
                }
                PortfolioHistoryView()
            }
            .padding()
        }
        .background(Color.black)
    }
}

//
//  portfolioview.swift
//  stox junior
//
//  Created by Aditya Kiran on 5/25/26.
//

