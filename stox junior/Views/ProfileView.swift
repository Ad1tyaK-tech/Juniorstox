import SwiftUI

struct ProfileView: View {

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var showAvatarPicker    = false
    @State private var showLinkEmail       = false
    @State private var showResetConfirm    = false
    @State private var showDeleteConfirm   = false
    @State private var pendingResetBalance: Double = 10_000
    @State private var showFinalReset      = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    settingsSection
                    accountSection
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }
            .background(AppColors.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerView().environmentObject(appState)
        }
        .sheet(isPresented: $showLinkEmail) {
            LinkEmailSheet().environmentObject(appState)
        }
        .confirmationDialog("Choose Starting Balance", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("$500 — High Risk")       { pendingResetBalance = 500;       showFinalReset = true }
            Button("$10,000 — Standard")    { pendingResetBalance = 10_000;    showFinalReset = true }
            Button("$100,000 — Cushioned")   { pendingResetBalance = 100_000;   showFinalReset = true }
            Button("$100,000,000 — Unlimited Freedom")   { pendingResetBalance = 100_000_000; showFinalReset = true }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Reset Portfolio?", isPresented: $showFinalReset) {
            Button("Reset Everything", role: .destructive) {
                appState.resetPortfolio(startingBalance: pendingResetBalance)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This erases all trades, gems, and achievements. Your login streak is kept. Starting balance: \(formatBalance(pendingResetBalance)).")
        }
        .alert("Delete Account?", isPresented: $showDeleteConfirm) {
            Button("Delete Forever", role: .destructive) { appState.deleteAccount() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your account and all data. It cannot be undone.")
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {

            ZStack(alignment: .bottomTrailing) {
                avatarCircle(size: 90)

                Button {
                    HapticsManager.click()
                    showAvatarPicker = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, AppColors.accent)
                }
                .offset(x: 4, y: 4)
            }

            Text(appState.fullName.isEmpty ? "No Name" : appState.fullName)
                .font(.title2.bold())
                .foregroundColor(AppColors.textPrimary)

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text("🔥")
                        Text("\(appState.currentStreak)")
                            .font(.title3.bold())
                            .foregroundColor(AppColors.textPrimary)
                            .monospacedDigit()
                    }
                    Text(streakMessage)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(AppColors.divider)
                    .frame(width: 1, height: 44)

                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text("💎")
                        Text("\(appState.gems)")
                            .font(.title3.bold())
                            .foregroundColor(AppColors.textPrimary)
                            .monospacedDigit()
                    }
                    Text("Gems")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppColors.cardBorder, lineWidth: 1))
    }

    @ViewBuilder
    private func avatarCircle(size: CGFloat) -> some View {
        let initials = appState.fullName
            .split(separator: " ").compactMap { $0.first }.map { String($0) }
            .joined().uppercased()

        Group {
            if let avatar = AvatarItem.all.first(where: { $0.id == appState.selectedAvatarId }),
               !appState.selectedAvatarId.isEmpty {
                AsyncImage(url: avatar.url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Text(String(avatar.name.prefix(1)))
                            .font(.system(size: size * 0.32, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            } else {
                Text(initials.isEmpty ? "?" : initials)
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
        .background(AppColors.accent)
        .clipShape(Circle())
        .overlay(Circle().stroke(AppColors.cardBorder, lineWidth: 1.5))
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("SETTINGS")

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "circle.lefthalf.filled")
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 28)
                    Text("Appearance")
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { appState.colorSchemePref },
                        set: { appState.colorSchemePref = $0; appState.saveToAccount() }
                    )) {
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                        Text("System").tag("system")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 168)
                }
                .padding(.vertical, 13)
                .padding(.horizontal, 16)

                rowDivider

                HStack {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 28)
                    Text("Haptics & Sounds")
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { !appState.hapticsDisabled },
                        set: { newValue in
                            if newValue {
                                appState.setHapticsDisabled(false)
                                HapticsManager.click()
                            } else {
                                appState.setHapticsDisabled(true)
                            }
                        }
                    )).labelsHidden()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                rowDivider

                toggleRow(icon: "antenna.radiowaves.left.and.right.slash", title: "Block Cellular Data",
                    isOn: Binding(
                        get: { appState.blockCellularData },
                        set: { appState.blockCellularData = $0; appState.saveToAccount() }
                    )
                )

                rowDivider

                Button {
                    HapticsManager.click()
                    showLinkEmail = true
                } label: {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 28)
                        Text("Link Account to Email")
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        if !appState.linkedEmail.isEmpty {
                            Text(appState.linkedEmail)
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: 130)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                }
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.cardBorder, lineWidth: 1))
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("ACCOUNT")

            VStack(spacing: 0) {
                Button {
                    HapticsManager.click()
                    showResetConfirm = true
                } label: {
                    actionRow(icon: "arrow.counterclockwise", title: "Reset Portfolio", color: AppColors.warning)
                }

                rowDivider

                Button {
                    HapticsManager.click()
                    appState.logout()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(AppColors.loss)
                            .frame(width: 28)
                        Text("Log Out")
                            .foregroundColor(AppColors.loss)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                }

                rowDivider

                Button {
                    HapticsManager.click()
                    showDeleteConfirm = true
                } label: {
                    actionRow(icon: "trash.fill", title: "Delete Account", color: AppColors.loss)
                }
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.cardBorder, lineWidth: 1))
        }
    }

    // MARK: - Helpers

    private var streakMessage: String {
        switch appState.currentStreak {
        case 0:     return "First time, huh? 👋"
        case 1:     return "Welcome back!"
        case 2...4: return "Good job keeping it up! 👍"
        case 5...9: return "You're on a roll! 🔥"
        default:    return "Unstoppable! 🚀"
        }
    }

    private func formatBalance(_ v: Double) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.maximumFractionDigits = 0
        return fmt.string(from: NSNumber(value: v)) ?? "$\(Int(v))"
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .tracking(1.0)
            .foregroundColor(AppColors.textSecondary)
            .padding(.leading, 4)
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 52)
    }

    @ViewBuilder
    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 28)
            Text(title)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func actionRow(icon: String, title: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            Text(title)
                .foregroundColor(color)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}

// MARK: - Avatar Picker

struct AvatarPickerView: View {

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var pendingUnlock: AvatarItem? = nil
    @State private var showNotEnoughGems = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    HStack(spacing: 6) {
                        Text("💎")
                        Text("\(appState.gems) gems available")
                            .font(.subheadline.bold())
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppColors.surfaceSecondary)
                    .clipShape(Capsule())
                    .padding(.top, 8)

                    ForEach(AvatarCategory.allCases, id: \.rawValue) { cat in
                        categorySection(cat)
                    }
                }
                .padding(.bottom, 30)
            }
            .background(AppColors.background)
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .confirmationDialog(
            "Unlock \(pendingUnlock?.name ?? "")?",
            isPresented: Binding(get: { pendingUnlock != nil }, set: { if !$0 { pendingUnlock = nil } }),
            titleVisibility: .visible
        ) {
            if let item = pendingUnlock {
                Button("Spend \(item.category.gemCost) 💎 to Unlock") {
                    appState.unlockAvatar(item.id)
                    appState.selectedAvatarId = item.id
                    pendingUnlock = nil
                    dismiss()
                }
                Button("Cancel", role: .cancel) { pendingUnlock = nil }
            }
        } message: {
            if let item = pendingUnlock {
                Text(appState.gems >= item.category.gemCost
                     ? "You have \(appState.gems) 💎. Tap to unlock!"
                     : "You need \(item.category.gemCost) 💎 but only have \(appState.gems).")
            }
        }
        .alert("Not Enough Gems", isPresented: $showNotEnoughGems) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Keep trading, completing daily challenges, and logging in every day to earn more 💎 gems!")
        }
    }

    @ViewBuilder
    private func categorySection(_ category: AvatarCategory) -> some View {
        let items = AvatarItem.all.filter { $0.category == category }

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: category.sfIcon)
                    .foregroundStyle(category.color)
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("💎 \(category.gemCost) each")
                    .font(.caption.bold())
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(items) { item in
                    avatarCell(item)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func avatarCell(_ item: AvatarItem) -> some View {
        let isOwned    = appState.ownedAvatarIds.contains(item.id)
        let isSelected = appState.selectedAvatarId == item.id
        let canAfford  = appState.gems >= item.category.gemCost

        Button {
            HapticsManager.click()
            if isOwned {
                appState.selectedAvatarId = item.id
                appState.saveToAccount()
                dismiss()
            } else if canAfford {
                pendingUnlock = item
            } else {
                showNotEnoughGems = true
            }
        } label: {
            VStack(spacing: 5) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(isSelected
                              ? item.category.color.opacity(0.18)
                              : (isOwned ? AppColors.surfaceSecondary : AppColors.inputBackground))
                        .frame(width: 58, height: 58)
                        .overlay(Circle().stroke(
                            isSelected ? item.category.color : Color.clear,
                            lineWidth: 2.5
                        ))

                    AsyncImage(url: item.url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Text(String(item.name.prefix(1)))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 58, height: 58)
                    .clipShape(Circle())
                    .opacity(isOwned ? 1.0 : 0.35)

                    if !isOwned {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(canAfford ? item.category.color : Color.gray.opacity(0.7)))
                            .offset(x: 2, y: -2)
                    } else if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, item.category.color)
                            .offset(x: 2, y: -2)
                    }
                }

                Text(item.name)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Link Email Sheet

private struct LinkEmailSheet: View {

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var emailInput = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Link your account to an email so you can recover it later.")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)

                TextField("your@email.com", text: $emailInput)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(14)
                    .background(AppColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding()
            .background(AppColors.background)
            .navigationTitle("Link Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        appState.linkedEmail = emailInput
                        appState.saveToAccount()
                        dismiss()
                    }
                    .disabled(emailInput.isEmpty || !emailInput.contains("@"))
                }
            }
        }
        .onAppear { emailInput = appState.linkedEmail }
    }
}
