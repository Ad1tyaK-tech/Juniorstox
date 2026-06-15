import SwiftUI
import SwiftData

struct CreateAccountView: View {

    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext

    @State private var fullName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String? = nil

    private var isPasswordValid: Bool { password.count >= 8 }
    private var passwordsMatch: Bool { password == confirmPassword && !password.isEmpty }
    private var canCreate: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        isPasswordValid && passwordsMatch
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
                            .padding()
                            .background(AppColors.inputBackground)
                            .foregroundColor(AppColors.textPrimary)
                            .cornerRadius(14)

                        SecureField("Password (8+ characters)", text: $password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding()
                            .background(AppColors.inputBackground)
                            .foregroundColor(AppColors.textPrimary)
                            .cornerRadius(14)

                        SecureField("Confirm Password", text: $confirmPassword)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding()
                            .background(AppColors.inputBackground)
                            .foregroundColor(AppColors.textPrimary)
                            .cornerRadius(14)

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
                        Text("Create Profile")
                            .fontWeight(.bold)
                            .foregroundColor(canCreate ? .white : AppColors.textTertiary)
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
        .onChange(of: fullName) { _, _ in errorMessage = nil }
    }

    private func createAccount() {
        let name = fullName.trimmingCharacters(in: .whitespaces)

        // Reject duplicate usernames
        let predicate = #Predicate<UserAccount> { $0.username == name }
        let descriptor = FetchDescriptor<UserAccount>(predicate: predicate)
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            errorMessage = "The name \"\(name)\" is already taken. Try a different name."
            return
        }

        let account = UserAccount(username: name, password: password)
        modelContext.insert(account)
        try? modelContext.save()

        appState.loadFrom(account, context: modelContext)
        appState.authState = .loggedIn
    }
}
