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
                .foregroundColor(AppColors.gain)

            Button("Logout") {
                appState.logout()
            }
            .foregroundColor(AppColors.loss)

            Spacer()
        }
        .padding()
    }
}
