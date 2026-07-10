import SwiftUI

struct LoginView: View {

    @EnvironmentObject var appState: AppState

    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading = false

    private var canAttempt: Bool { !username.isEmpty && !password.isEmpty && !isLoading }

    var body: some View {

        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        appState.authState = .welcome
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(AppColors.textPrimary)
                            .font(.title3)
                    }
                    Spacer()
                }
                .padding()

                Spacer()

                VStack(spacing: 25) {

                    Spacer()

                    Text("Welcome back")
                        .font(.largeTitle.bold())
                        .foregroundColor(AppColors.textPrimary)

                    Text("Log in to your account")
                        .foregroundColor(AppColors.textSecondary)

                    VStack(spacing: 16) {

                        TextField("Username", text: $username)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled(true)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(AppColors.inputBackground)
                            .foregroundColor(AppColors.textPrimary)
                            .cornerRadius(14)

                        SecureField("Password", text: $password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(AppColors.inputBackground)
                            .foregroundColor(AppColors.textPrimary)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 30)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(AppColors.loss)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }

                    Button {
                        attemptLogin()
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Log In").fontWeight(.bold)
                                    .foregroundColor(canAttempt ? .white : AppColors.textTertiary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canAttempt ? AppColors.accent : AppColors.inputBackground)
                        .cornerRadius(14)
                        .padding(.horizontal, 30)
                    }
                    .disabled(!canAttempt)

                    Button {
                        appState.authState = .forgotPassword
                    } label: {
                        Text("Forgot password?")
                            .font(.subheadline)
                            .foregroundColor(errorMessage != nil ? AppColors.warning : AppColors.textTertiary)
                    }

                    Spacer()
                }
            }
        }
        .onChange(of: username) { _, _ in errorMessage = nil }
        .onChange(of: password) { _, _ in errorMessage = nil }
    }

    private func attemptLogin() {
        let name = username.trimmingCharacters(in: .whitespaces)
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await appState.attemptLogin(username: name, password: password)
                RecoveryRateLimiter().reset()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
