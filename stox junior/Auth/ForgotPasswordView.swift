import SwiftUI
import SwiftData

struct ForgotPasswordView: View {

    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext

    @State private var email = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String? = nil
    @State private var foundAccount: UserAccount? = nil
    @State private var didReset = false

    private var isPasswordValid: Bool { newPassword.count >= 8 }
    private var passwordsMatch: Bool { newPassword == confirmPassword && !newPassword.isEmpty }
    private var canReset: Bool { isPasswordValid && passwordsMatch }

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
        .onChange(of: email) { _, _ in errorMessage = nil }
        .onChange(of: newPassword) { _, _ in errorMessage = nil }
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

            Text("Enter the email linked to your account\nand we'll let you reset your password.")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            TextField("Email address", text: $email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.emailAddress)
                .padding()
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
                Text("Find My Account")
                    .fontWeight(.bold)
                    .foregroundColor(email.isEmpty ? AppColors.textTertiary : .white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(email.isEmpty ? AppColors.inputBackground : AppColors.accent)
                    .cornerRadius(14)
                    .padding(.horizontal, 30)
            }
            .disabled(email.isEmpty)

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
                    .padding()
                    .background(AppColors.inputBackground)
                    .foregroundColor(AppColors.textPrimary)
                    .cornerRadius(14)

                SecureField("Confirm New Password", text: $confirmPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding()
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
                Text("Save New Password")
                    .fontWeight(.bold)
                    .foregroundColor(canReset ? .white : AppColors.textTertiary)
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
        errorMessage = nil
        let trimmed = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return }

        let descriptor = FetchDescriptor<UserAccount>()
        guard let accounts = try? modelContext.fetch(descriptor) else {
            errorMessage = "Could not search accounts."
            return
        }

        // Email is stored inside settingsJSON — decode just what we need
        struct EmailCheck: Decodable { var linkedEmail: String = "" }
        let match = accounts.first { account in
            guard let data = account.settingsJSON.data(using: .utf8),
                  let check = try? JSONDecoder().decode(EmailCheck.self, from: data) else { return false }
            return check.linkedEmail.trimmingCharacters(in: .whitespaces).lowercased() == trimmed
        }

        if let match {
            foundAccount = match
        } else {
            errorMessage = "No account found with that email.\nIf you didn't add an email when signing up, ask a parent for help."
        }
    }

    private func saveNewPassword(for account: UserAccount) {
        guard canReset else { return }
        account.passwordHash = UserAccount.hash(newPassword)
        try? modelContext.save()
        didReset = true
    }
}
