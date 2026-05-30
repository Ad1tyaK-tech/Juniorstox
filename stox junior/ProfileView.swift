import SwiftUI

struct ProfileView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {

        VStack(spacing: 20) {

            ProfileButton()
                .scaleEffect(2)

            Text(appState.fullName.isEmpty ? "No Name" : appState.fullName)
                .font(.title.bold())

            Text("Cash: $\(appState.cashBalance, specifier: "%.2f")")
                .foregroundColor(.green)

            Button("Logout") {
                appState.authState = .welcome
                appState.ownedStocks = []
                appState.cashBalance = 10000
            }
            .foregroundColor(.red)

            Spacer()
        }
        .padding()
    }
}//
//  profileview.swift
//  stox junior
//
//  Created by Aditya Kiran on 5/25/26.
//

