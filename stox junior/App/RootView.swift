import SwiftUI

struct RootView: View {

    @StateObject var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {

        Group {
            switch appState.authState {
            case .loading:
                ZStack {
                    AppColors.background.ignoresSafeArea()
                    ProgressView()
                        .tint(AppColors.accent)
                        .scaleEffect(1.5)
                }
            case .welcome:        WelcomeView()
            case .login:          LoginView()
            case .signup:         CreateAccountView()
            case .forgotPassword:  ForgotPasswordView()
            case .privacyConsent:  PrivacyPolicyView()
            case .loggedIn:        MainDashboardView()
            }
        }
        .environmentObject(appState)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                // Fill in net-worth snapshots for any hours spent outside the app
                appState.catchUpSnapshots()
            }
        }
    }
}
