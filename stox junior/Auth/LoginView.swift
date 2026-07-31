import SwiftUI

struct LoginView: View {

    @EnvironmentObject var appState: AppState

    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading = false
    @State private var lockState: LoginRateLimiter.LockState = LoginRateLimiter().lockState()

    private var canAttempt: Bool {
        guard case .allowed = lockState else { return false }
        return !username.isEmpty && !password.isEmpty && !isLoading
    }

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

                    lockoutBanner

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

                    if case .softLocked = lockState {
                        Button {
                            appState.authState = .signup
                        } label: {
                            Text("Create New Account")
                                .font(.subheadline)
                                .foregroundColor(AppColors.accent)
                        }
                    }

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
        .task {
            while true {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                let updated = LoginRateLimiter().lockState()
                if updated != lockState { lockState = updated }
            }
        }
    }

    @ViewBuilder
    private var lockoutBanner: some View {
        switch lockState {
        case .allowed:
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(AppColors.loss)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
        case .softLocked(let until):
            Text("Too many failed attempts. Try again in \(timeRemaining(until)).")
                .font(.caption)
                .foregroundColor(AppColors.loss)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        case .dayLocked(let until):
            Text("Account locked. Try again in \(timeRemaining(until)).")
                .font(.caption)
                .foregroundColor(AppColors.loss)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        case .indefinite:
            Text("Login access has been permanently restricted on this device.")
                .font(.caption)
                .foregroundColor(AppColors.loss)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
    }

    private func timeRemaining(_ date: Date) -> String {
        let secs = max(0, Int(date.timeIntervalSinceNow))
        if secs >= 3600 { return "\(secs / 3600)h \((secs % 3600) / 60)m" }
        if secs >= 60   { return "\(secs / 60)m \(secs % 60)s" }
        return "\(secs)s"
    }

    private func attemptLogin() {
        let name = username.trimmingCharacters(in: .whitespaces)
        isLoading = true
        errorMessage = nil
        let limiter = LoginRateLimiter()
        Task {
            do {
                try await appState.attemptLogin(username: name, password: password)
                limiter.recordSuccess()
                RecoveryRateLimiter().reset()
            } catch {
                limiter.recordFailure()
                lockState = limiter.lockState()
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
