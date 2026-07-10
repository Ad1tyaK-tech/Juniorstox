import SwiftUI

struct CreateAccountView: View {

    @EnvironmentObject var appState: AppState

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading = false

    private let currentYear = Calendar.current.component(.year, from: .now)
    @State private var birthYear: Int = Calendar.current.component(.year, from: .now) - 16

    private var isAgeValid: Bool { currentYear - birthYear >= 13 }
    private var isPasswordValid: Bool { password.count >= 8 }
    private var passwordsMatch: Bool { password == confirmPassword && !password.isEmpty }
    private var canCreate: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        isPasswordValid && passwordsMatch && isAgeValid && !isLoading
    }

    var body: some View {

        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack {

                HStack {
                    Button { appState.authState = .welcome } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(AppColors.textPrimary)
                            .font(.title3)
                    }
                    Spacer()
                }
                .padding()

                Spacer()

                VStack(spacing: 25) {

                    Text("Create Account")
                        .font(.largeTitle.bold())
                        .foregroundColor(AppColors.textPrimary)

                    Text("Start your financial journey.")
                        .foregroundColor(AppColors.textSecondary)

                    VStack(spacing: 16) {

                        TextField("Your Name", text: $fullName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled(true)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(AppColors.inputBackground)
                            .foregroundColor(AppColors.textPrimary)
                            .cornerRadius(14)

                        HStack {
                            Text("Birth Year")
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Picker("Birth Year", selection: $birthYear) {
                                ForEach(Array((currentYear - 100)...currentYear).reversed(), id: \.self) { year in
                                    Text(String(year)).tag(year)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(AppColors.accent)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(AppColors.inputBackground)
                        .cornerRadius(14)

                        if !isAgeValid {
                            Text("You must be 13 or older to create an account")
                                .font(.caption)
                                .foregroundColor(AppColors.loss)
                        }

                        SecureField("Password (8+ characters)", text: $password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(AppColors.inputBackground)
                            .foregroundColor(AppColors.textPrimary)
                            .cornerRadius(14)

                        SecureField("Confirm Password", text: $confirmPassword)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(AppColors.inputBackground)
                            .foregroundColor(AppColors.textPrimary)
                            .cornerRadius(14)

                        VStack(spacing: 0) {
                            TextField("Email/Keycode (optional)", text: $email)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .keyboardType(.default)
                                .padding()
                                .background(AppColors.inputBackground)
                                .foregroundColor(AppColors.textPrimary)
                                .cornerRadius(14)

                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "lock.shield")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.textTertiary)
                                    .padding(.top, 1)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Email is optional. It will only act as a keyword for your account recovery")
                                        .font(.caption2)
                                        .foregroundColor(AppColors.textTertiary)
                                    Text("Without one, a forgotten password means a lost account.")
                                        .font(.caption2)
                                        .foregroundColor(AppColors.warning)
                                }
                            }
                            .padding(.top, 6)
                            .padding(.horizontal, 4)
                        }

                        if !password.isEmpty && !isPasswordValid {
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
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }

                    Button { createAccount() } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Profile").fontWeight(.bold)
                                    .foregroundColor(canCreate ? .white : AppColors.textTertiary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canCreate ? AppColors.accent : AppColors.inputBackground)
                        .cornerRadius(18)
                        .padding(.horizontal, 30)
                    }
                    .disabled(!canCreate)

                    Spacer()
                }
            }
        }
        .onChange(of: fullName)    { _, _ in errorMessage = nil }
        .onChange(of: email)       { _, _ in errorMessage = nil }
        .onChange(of: birthYear)   { _, _ in errorMessage = nil }
    }

    private func createAccount() {
        let name    = fullName.trimmingCharacters(in: .whitespaces)
        let trimEmail = email.trimmingCharacters(in: .whitespaces)
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await appState.attemptCreateAccount(username: name, password: password, email: trimEmail)
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
