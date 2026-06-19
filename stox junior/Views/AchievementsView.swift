import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(AchievementDef.all) { def in
                        AchievementCard(def: def)
                    }
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Card

private struct AchievementCard: View {
    @EnvironmentObject var appState: AppState
    let def: AchievementDef

    // Four possible states for each tier slot
    private enum TierState { case claimed, claimable, active, locked }

    var body: some View {
        let progress   = appState.achievementProgress(for: def.id)
        let claimable  = claimableTier(progress: progress)
        let active     = activeTier(progress: progress)
        let topClaimed = highestClaimedTier()
        let hasClaim   = claimable != nil

        VStack(alignment: .leading, spacing: 10) {

            // Header: icon + title + highest-claimed badge
            HStack(spacing: 10) {
                Image(systemName: def.icon)
                    .font(.title2)
                    .foregroundStyle(topClaimed.map { tierColor($0) } ?? AppColors.textTertiary)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(def.title.uppercased())
                            .font(.caption.bold())
                            .tracking(0.8)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        if let t = topClaimed {
                            Text(t.label)
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(tierColor(t))
                                .clipShape(Capsule())
                        }
                    }
                    // Subtitle: describe what you're working toward
                    Group {
                        if let c = claimable {
                            Text(def.description(for: c))
                        } else if let a = active {
                            Text(def.description(for: a))
                        } else {
                            Text("All tiers complete! 🏆")
                                .foregroundStyle(AppColors.gain)
                        }
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.textPrimary)
                }
            }

            // Claim button when a tier's threshold has been reached
            if let c = claimable {
                Button {
                    HapticsManager.celebrate()
                    SoundManager.shared.playCelebration()
                    appState.claimAchievementTier(id: def.id, tier: c)
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                        Text("Claim \(c.label)")
                            .font(.subheadline.bold())
                        Spacer()
                        Text("💎 +\(c.gemReward)")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(tierColor(c))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(tierColor(c).opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(tierColor(c), lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else if let a = active {
                // Progress bar while working toward the next threshold
                let target   = def.threshold(for: a)
                let fraction = min(Double(progress) / Double(target), 1.0)
                HStack(spacing: 8) {
                    ProgressView(value: fraction)
                        .tint(tierColor(a))
                    Text("\(progress)/\(target)")
                        .font(.caption2.bold())
                        .foregroundStyle(AppColors.textSecondary)
                        .monospacedDigit()
                        .frame(minWidth: 48, alignment: .trailing)
                    HStack(spacing: 2) {
                        Text("💎").font(.caption2)
                        Text("+\(a.gemReward)")
                            .font(.caption2.bold())
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
            }

            // Tier trail — only shows accessible tiers (claimed + claimable + active).
            // Locked tiers are hidden; you only see what you can reach right now.
            let visible = AchievementTier.allCases.filter {
                tierState(tier: $0, progress: progress) != .locked
            }
            if !visible.isEmpty {
                HStack(spacing: 0) {
                    ForEach(Array(visible.enumerated()), id: \.element.rawValue) { idx, tier in
                        tierDot(tier: tier, state: tierState(tier: tier, progress: progress))
                        if idx < visible.count - 1 {
                            Rectangle()
                                .fill(AppColors.divider)
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 14)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    hasClaim
                        ? tierColor(claimable!).opacity(0.70)
                        : (topClaimed.map { tierColor($0).opacity(0.35) } ?? AppColors.cardBorder),
                    lineWidth: hasClaim ? 1.5 : 1
                )
        )
    }

    // MARK: - Tier state helpers

    private func tierState(tier: AchievementTier, progress: Int) -> TierState {
        if appState.isTierClaimed(id: def.id, tier: tier) { return .claimed }
        // Previous tier must be claimed (or it's amateur) for this tier to be visible
        let prevClaimed: Bool
        if tier == .amateur {
            prevClaimed = true
        } else {
            let prev = AchievementTier(rawValue: tier.rawValue - 1)!
            prevClaimed = appState.isTierClaimed(id: def.id, tier: prev)
        }
        guard prevClaimed else { return .locked }
        return progress >= def.threshold(for: tier) ? .claimable : .active
    }

    // First tier that is ready to claim (threshold met, previous claimed, not yet claimed)
    private func claimableTier(progress: Int) -> AchievementTier? {
        AchievementTier.allCases.first {
            appState.isTierClaimable(id: def.id, tier: $0)
        }
    }

    // First tier whose threshold hasn't been met yet but is accessible
    private func activeTier(progress: Int) -> AchievementTier? {
        for tier in AchievementTier.allCases {
            let state = tierState(tier: tier, progress: progress)
            if state == .active { return tier }
        }
        return nil
    }

    private func highestClaimedTier() -> AchievementTier? {
        AchievementTier.allCases.reversed().first {
            appState.isTierClaimed(id: def.id, tier: $0)
        }
    }

    // MARK: - Colours

    private func tierColor(_ tier: AchievementTier) -> Color {
        switch tier {
        case .amateur:  return Color(red: 0.20, green: 0.68, blue: 0.35)
        case .bronze:   return Color(red: 0.75, green: 0.45, blue: 0.15)
        case .silver:   return Color(red: 0.50, green: 0.56, blue: 0.62)
        case .gold:     return Color(red: 0.88, green: 0.70, blue: 0.05)
        case .platinum: return Color(red: 0.42, green: 0.78, blue: 0.95)
        }
    }

    // MARK: - Tier dot

    @ViewBuilder
    private func tierDot(tier: AchievementTier, state: TierState) -> some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(state == .claimed || state == .claimable
                          ? tierColor(tier)
                          : tierColor(tier).opacity(0.14))
                    .frame(width: 30, height: 30)
                switch state {
                case .claimed:
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                case .claimable:
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.white)
                case .active:
                    Image(systemName: tier.sfBadge)
                        .font(.system(size: 11))
                        .foregroundStyle(tierColor(tier))
                case .locked:
                    EmptyView()
                }
            }
            Text(tier.label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}
