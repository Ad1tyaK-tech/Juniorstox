import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {

            // Background Gradient
            AppColors.welcomeGradient
                .ignoresSafeArea()

            // Floating circles for visual depth
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 250)
                .blur(radius: 10)
                .offset(x: 120, y: -250)

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 300)
                .blur(radius: 20)
                .offset(x: -150, y: 250)

            VStack(spacing: 25) {

                Spacer()

                // App Logo
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 70))
                    .foregroundColor(.white)

                // App Name
                Text("Stox")
                    .font(.system(size: 55, weight: .bold))
                    .foregroundColor(.white)

                // Subtitle
                Text("A Digital Marketplace")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))

                Text("Learn markets, trends, and investing through interactive simulations.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 35)
                    .foregroundColor(.white.opacity(0.75))

                Spacer()

                VStack(spacing: 18) {

                    Button {
                        appState.authState = .signup
                    } label: {
                        Text("Build an Account")
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.accentDeep)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(18)
                    }

                    Button(action: {
                        appState.authState = .login
                    }) {
                        Text("Log In")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 30)
            }
        }
    }
}
