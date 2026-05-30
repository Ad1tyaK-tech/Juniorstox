import SwiftUI

struct RootView: View {

    @StateObject var appState = AppState()

    var body: some View {

        Group {
            switch appState.authState {

            case .welcome:
                WelcomeView()

            case .login:
                LoginView()

            case .signup:
                CreateAccountView()

            case .loggedIn:
                MainDashboardView()
            }
        }
        .environmentObject(appState)
    }
}
