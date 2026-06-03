import SwiftUI

struct StockCard: View {

    let stock: Stock

    var body: some View {

        HStack {

            VStack(alignment: .leading, spacing: 6) {

                Text(stock.company)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(stock.symbol)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {

                Text("$\(stock.price, specifier: "%.2f")")
                    .foregroundColor(.white)

                Text(
                    "\(stock.changePercent, specifier: "%.5f")%"
                )
                .foregroundColor(
                    stock.changePercent >= 0
                    ? .green
                    : .red
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(18)
    }
}//
//  stockcard.swift
//  stox junior
//
//  Created by Aditya Kiran on 5/25/26.
//

