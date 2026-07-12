import SwiftUI

struct PrivacyPolicyView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {

                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.accent)
                        .padding(.bottom, 4)
                    Text("Your Privacy")
                        .font(.largeTitle.bold())
                        .foregroundColor(AppColors.textPrimary)
                    Text("What we do with your data.")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 48)
                .padding(.bottom, 28)

                ScrollView {
                    VStack(spacing: 16) {

                        PrivacySection(title: "What we store", icon: "internaldrive", iconColor: AppColors.accent) {
                            PrivacyRow(icon: "person.fill",               label: "Username",          detail: "Used to identify your account")
                            PrivacyRow(icon: "lock.fill",                 label: "Password",          detail: "Stored securely so we can never read it")
                            PrivacyRow(icon: "envelope.fill",             label: "Email (optional)",  detail: "Only for account recovery, never for marketing")
                            PrivacyRow(icon: "chart.line.uptrend.xyaxis", label: "Portfolio activity",detail: "Simulated trades, balance, and history are synced so you can pick up where you left off")
                            PrivacyRow(icon: "flame.fill",                label: "App opens",         detail: "Timestamps used only to count your login streak")
                        }

                        PrivacySection(title: "What we never collect", icon: "nosign", iconColor: Color.green) {
                            PrivacyRow(icon: "location.slash.fill",                    label: "Location",                detail: "Never")
                            PrivacyRow(icon: "creditcard.trianglebadge.exclamationmark", label: "Real money or payments", detail: "Everything is simulated")
                            PrivacyRow(icon: "person.2.slash",                         label: "Contacts",                detail: "Never accessed")
                            PrivacyRow(icon: "eye.slash.fill",                         label: "Advertising identifiers", detail: "No ad tracking")
                        }

                        PrivacySection(title: "We never share your data", icon: "hand.raised.fill", iconColor: Color.orange) {
                            PrivacyRow(icon: "xmark.circle.fill", label: "No third-party sharing", detail: "Your data stays in your account")
                            PrivacyRow(icon: "xmark.circle.fill", label: "No data selling",        detail: "We don't sell or rent your information to anyone")
                        }

                        PrivacySection(title: "You're in control", icon: "slider.horizontal.3", iconColor: Color.purple) {
                            PrivacyRow(icon: "trash.fill", label: "Delete anytime", detail: "Profile → Delete Account removes everything permanently")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }

            // Accept button pinned to bottom
            Button {
                appState.showTutorial = true
                appState.tutorialStep = 0
                appState.authState = .loggedIn
            } label: {
                Text("I Understand — Let's Go!")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.accent)
                    .cornerRadius(18)
                    .padding(.horizontal, 30)
            }
            .padding(.vertical, 16)
            .background(AppColors.background)
        }
    }
}

private struct PrivacySection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.subheadline.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            content()
        }
        .padding(16)
        .background(AppColors.inputBackground)
        .cornerRadius(16)
    }
}

private struct PrivacyRow: View {
    let icon: String
    let label: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.textSecondary)
                .font(.footnote)
                .frame(width: 16)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}
