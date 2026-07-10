import SwiftUI

// Tracks failed keycode attempts per device. Persists across app restarts via UserDefaults.
// Lockout schedule: fail 5 → 5 min | fail 7 → 10 min | fail 9 → 1 hr | fail 10 → 1 day | fail 13+ → indefinite
// Warning shown at fails 11 and 12 (2 / 1 attempt remaining before permanent lockout).
struct RecoveryRateLimiter {
    private let failKey = "recovery.failCount"
    private let lockKey = "recovery.lockedUntil"

    // 100-year sentinel represents "indefinite" — distinguishable from finite locks.
    private let indefiniteDuration: TimeInterval = 100 * 365 * 24 * 3600

    func failCount() -> Int { UserDefaults.standard.integer(forKey: failKey) }

    func lockExpiry() -> Date? {
        let t = UserDefaults.standard.double(forKey: lockKey)
        guard t > 0 else { return nil }
        return Date(timeIntervalSince1970: t)
    }

    func isCurrentlyLocked() -> Bool {
        guard let exp = lockExpiry() else { return false }
        return exp > .now
    }

    func isIndefinite() -> Bool {
        guard let exp = lockExpiry() else { return false }
        return exp.timeIntervalSinceNow > indefiniteDuration / 2
    }

    // Increments fail count and sets the appropriate lockout window.
    // Returns the new expiry, or nil if the attempt count hasn't crossed a threshold yet.
    @discardableResult
    func recordFailure() -> Date? {
        let newCount = failCount() + 1
        UserDefaults.standard.set(newCount, forKey: failKey)

        let duration: TimeInterval
        switch newCount {
        case 5:       duration = 5 * 60
        case 7:       duration = 10 * 60
        case 9:       duration = 60 * 60
        case 10:       duration = 24 * 60 * 60
        default:
            guard newCount >= 13 else { return nil }
            duration = indefiniteDuration
        }

        let expiry = Date(timeIntervalSinceNow: duration)
        UserDefaults.standard.set(expiry.timeIntervalSince1970, forKey: lockKey)
        return expiry
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: failKey)
        UserDefaults.standard.removeObject(forKey: lockKey)
    }

    func formattedRemaining(_ seconds: Int) -> String {
        if seconds >= 3600 {
            let h = seconds / 3600; let m = (seconds % 3600) / 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        } else if seconds >= 60 {
            let m = seconds / 60; let s = seconds % 60
            return s > 0 ? "\(m)m \(s)s" : "\(m)m"
        } else {
            return "\(seconds)s"
        }
    }
}

struct ForgotPasswordView: View {

    @EnvironmentObject var appState: AppState

    @State private var email = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String? = nil
    @State private var foundAccount: UserAccount? = nil
    @State private var didReset = false
    @State private var isLoading = false

    @State private var isLocked = false
    @State private var countdown: String? = nil
    @State private var countdownTask: Task<Void, Never>? = nil

    private let limiter = RecoveryRateLimiter()

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
        .onAppear { startCountdown() }
        .onDisappear { countdownTask?.cancel() }
        .onChange(of: email)           { _, _ in errorMessage = nil }
        .onChange(of: newPassword)     { _, _ in errorMessage = nil }
        .onChange(of: confirmPassword) { _, _ in errorMessage = nil }
    }

    // MARK: - Phase 1: Enter Email

    private var emailEntryView: some View {
        VStack(spacing: 25) {
            Image(systemName: isLocked ? "lock.fill" : "key.fill")
                .font(.system(size: 48))
                .foregroundColor(isLocked ? AppColors.loss : AppColors.accent)

            Text(isLocked ? "Too Many Attempts" : "Forgot Password?")
                .font(.largeTitle.bold())
                .foregroundColor(AppColors.textPrimary)

            if isLocked {
                lockedMessageView
            } else {
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
            }

            Button {
                appState.authState = .login
            } label: {
                Text("Back to Login")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }

    private var lockedMessageView: some View {
        VStack(spacing: 12) {
            if limiter.isIndefinite() {
                Text("Account recovery has been disabled on this device due to too many failed attempts.")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            } else {
                Text("Account recovery is temporarily locked.")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                if let cd = countdown {
                    Text("Try again in \(cd)")
                        .font(.title3.monospacedDigit().bold())
                        .foregroundColor(AppColors.loss)
                }
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
        guard !isLocked else { return }
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                if let match = try await appState.accountService.findByEmail(trimmed) {
                    limiter.reset()
                    foundAccount = match
                } else {
                    limiter.recordFailure()
                    startCountdown()
                    if isLocked {
                        errorMessage = nil
                    } else {
                        let count = limiter.failCount()
                        switch count {
                        case 11:
                            errorMessage = "No account found.\n⚠️ Warning: 2 more failed attempts will permanently disable account recovery on this device."
                        case 12:
                            errorMessage = "No account found.\n⚠️ Final warning: 1 more failed attempt will permanently disable account recovery."
                        default:
                            errorMessage = "No account found with that keycode.\nMake sure it matches exactly what you set in Profile → Account Recovery."
                        }
                    }
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

    // MARK: - Countdown

    private func startCountdown() {
        countdownTask?.cancel()

        guard limiter.isCurrentlyLocked() else {
            isLocked = false
            countdown = nil
            return
        }

        isLocked = true

        guard !limiter.isIndefinite(), let expiry = limiter.lockExpiry() else {
            countdown = nil
            return
        }

        countdownTask = Task {
            while !Task.isCancelled {
                let remaining = Int(expiry.timeIntervalSinceNow)
                if remaining <= 0 {
                    isLocked = false
                    countdown = nil
                    break
                }
                countdown = limiter.formattedRemaining(remaining)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
}
