import SwiftUI

struct PortfolioHistoryView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {

        VStack(alignment: .leading) {

            Text("Portfolio Growth")
                .font(.title.bold())
                .foregroundColor(.white)

            ScrollView(.horizontal) {

                HStack(alignment: .bottom, spacing: 4) {

                    ForEach(0..<appState.portfolioHistory.count, id: \.self) { index in

                        let value = appState.portfolioHistory[index]

                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 10, height: CGFloat(value / 100))
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color.black)
    }
}
//  historyview.swift
//  stox junior
//
//  Created by Aditya Kiran on 5/25/26.
//

