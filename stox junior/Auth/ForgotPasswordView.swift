import SwiftUI

struct ForgotPasswordView: View {

    @EnvironmentObject var appState: AppState

    @State private var email = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String? = nil
    @State private var foundAccount: UserAccount? = nil
    @State private var didReset = false
    @State private var isLoading = false

    private var isPasswordValid: Bool { newPassword.count >= 8 }
    private var passwordsMatch: Bool { newPassword == confirmPassword && !newPassword.isEmpty }
    private var canReset: Bool { isPasswordValid && passwordsMatch && !isLoading }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        appState.authState = .login
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(AppColors.textPrimary)
                            .font(.title3)
                    }
                    Spacer()
                }
                .padding()

                Spacer()

                if didReset {
                    successView
                } else if let account = foundAccount {
                    resetView(for: account)
                } else {
                    emailEntryView
                }

                Spacer()
            }
        }
        .onChange(of: email)           { _, _ in errorMessage = nil }
        .onChange(of: newPassword)     { _, _ in errorMessage = nil }
        .onChange(of: confirmPassword) { _, _ in errorMessage = nil }
    }

    // MARK: - Phase 1: Enter Email

    private var emailEntryView: some View {
        VStack(spacing: 25) {
            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.accent)

            Text("Forgot Password?")
                .font(.largeTitle.bold())
                .foregroundColor(AppColors.textPrimary)

            Text("Enter the recovery keycode linked to your account.")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            TextField("Recovery keycode", text: $email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.default)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(AppColors.inputBackground)
                .foregroundColor(AppColors.textPrimary)
                .cornerRadius(14)
                .padding(.horizontal, 30)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(AppColors.loss)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }

            Button {
                findAccount()
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Find My Account").fontWeight(.bold)
                            .foregroundColor(email.isEmpty ? AppColors.textTertiary : .white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(email.isEmpty ? AppColors.inputBackground : AppColors.accent)
                .cornerRadius(14)
                .padding(.horizontal, 30)
            }
            .disabled(email.isEmpty || isLoading)

            Button {
                appState.authState = .login
            } label: {
                Text("Back to Login")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }

    // MARK: - Phase 2: Reset Password

    private func resetView(for account: UserAccount) -> some View {
        VStack(spacing: 25) {
            Image(systemName: "lock.rotation")
                .font(.system(size: 48))
                .foregroundColor(AppColors.accent)

            Text("Reset Password")
                .font(.largeTitle.bold())
                .foregroundColor(AppColors.textPrimary)

            Text("Account found: \(account.username)")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)

            VStack(spacing: 16) {
                SecureField("New Password (8+ characters)", text: $newPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(AppColors.inputBackground)
                    .foregroundColor(AppColors.textPrimary)
                    .cornerRadius(14)

                SecureField("Confirm New Password", text: $confirmPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(AppColors.inputBackground)
                    .foregroundColor(AppColors.textPrimary)
                    .cornerRadius(14)

                if !newPassword.isEmpty && !isPasswordValid {
                    Text("Password must be at least 8 characters")
                        .font(.caption)
                        .foregroundColor(AppColors.loss)
                }
                if !confirmPassword.isEmpty && !passwordsMatch {
                    Text("Passwords don't match")
                        .font(.caption)
                        .foregroundColor(AppColors.loss)
                }
            }
            .padding(.horizontal, 30)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(AppColors.loss)
                    .padding(.horizontal, 30)
            }

            Button {
                saveNewPassword(for: account)
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Save New Password").fontWeight(.bold)
                            .foregroundColor(canReset ? .white : AppColors.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canReset ? AppColors.accent : AppColors.inputBackground)
                .cornerRadius(14)
                .padding(.horizontal, 30)
            }
            .disabled(!canReset)
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 25) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.gain)

            Text("Password Reset!")
                .font(.largeTitle.bold())
                .foregroundColor(AppColors.textPrimary)

            Text("Your new password has been saved.\nYou can now log in.")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                appState.authState = .login
            } label: {
                Text("Go to Login")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.accent)
                    .cornerRadius(14)
                    .padding(.horizontal, 30)
            }
        }
    }

    // MARK: - Logic

    private func findAccount() {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                if let match = try await appState.accountService.findByEmail(trimmed) {
                    foundAccount = match
                } else {
                    errorMessage = "No account found with that keycode.\nMake sure it matches exactly what you set in Profile → Link Account to Email."
                }
            } catch {
                errorMessage = "Could not search accounts. Check your connection."
            }
            isLoading = false
        }
    }

    private func saveNewPassword(for account: UserAccount) {
        guard canReset else { return }
        isLoading = true
        var updated = account
        updated.passwordHash = UserAccount.hash(newPassword)
        Task {
            do {
                try await appState.accountService.save(updated)
                didReset = true
            } catch {
                errorMessage = "Failed to save new password. Check your connection."
            }
            isLoading = false
        }
    }
}
