import SwiftUI

// MARK: - Data model

private enum TutorialArrow {
    case none, topLeft, topRight, upper, middle, lower
}

private struct TutorialStep {
    let title: String
    let body: String
    let tab: Int?           // nil = keep current tab
    let arrow: TutorialArrow
    let allowsTaps: Bool    // when true, backdrop passes taps through to content below
    let hasNavBar: Bool     // when true, adds nav-bar height to content top bound
    let forceAction: Bool   // when true, Next button is hidden — only the user action advances

    init(title: String, body: String, tab: Int?, arrow: TutorialArrow,
         allowsTaps: Bool = false, hasNavBar: Bool = false, forceAction: Bool = false) {
        self.title = title; self.body = body; self.tab = tab; self.arrow = arrow
        self.allowsTaps = allowsTaps; self.hasNavBar = hasNavBar; self.forceAction = forceAction
    }
}

// Step index 5 is the "tap a stock" gate — StockAnalysisView auto-advances past it.
let tutorialStockTapStep = 5

private let tutorialSteps: [TutorialStep] = [
    // 0 — Welcome (full-screen)
    .init(title: "Welcome to Stox Junior! 🎉",
          body: "You just got $10,000 in virtual cash. Let's take a quick tour so you know exactly what to do.",
          tab: 0, arrow: .none),

    // 1 — Home overview
    .init(title: "Your Home Screen 🏠",
          body: "Home shows your cash balance, today's market highlights, and quick stats. It's your launchpad every time you open the app.",
          tab: 0, arrow: .middle),

    // 2 — Daily Challenge
    .init(title: "Daily Challenge ⭐",
          body: "Each day there's a small trading task. Complete it to earn 5 💎 Gems. Challenges reset at midnight — don't miss out!",
          tab: 0, arrow: .upper),

    // 3 — Net Worth card
    .init(title: "Net Worth Card",
          body: "This tracks your total wealth — your cash plus the live value of all your stocks. Tap it to jump to your full history chart.",
          tab: 0, arrow: .middle),

    // 4 — Market sectors (auto-switch to tab 1)
    .init(title: "The Market 📈",
          body: "Stocks are organized by sector — Big Tech, Chip Makers, Shopping, and more. Pull down to refresh prices. Tap any sector header to expand or collapse it.",
          tab: 1, arrow: .middle),

    // 5 — Tap a stock (backdrop non-blocking; StockAnalysisView.onAppear auto-advances to step 6)
    .init(title: "Explore a Stock",
          body: "Tap any stock card below to open its full analysis — live data, a 90-day chart, and AI-powered insights.",
          tab: 1, arrow: .lower,
          allowsTaps: true, forceAction: true),

    // 6 — Analysis: Insight card + chart
    .init(title: "Insight & 90-Day Chart 💡",
          body: "The Insight card gives a plain-English read on today's action. Below it is a 90-day price chart plotting each day's closing price — great for spotting long-term trends.",
          tab: nil, arrow: .upper, hasNavBar: true),

    // 7 — Analysis: Trend Signal + Market Data rows
    .init(title: "Trend Signal & Market Data",
          body: "The Trend Signal (Bullish / Bearish / Neutral) is calculated from the 20-day average and price slope. Market Data rows below break down today's high, low, and daily % change. Tap the ℹ️ on any row for a plain-English explanation.",
          tab: nil, arrow: .middle, hasNavBar: true),

    // 8 — Analysis: Advanced dropdown (backdrop non-blocking so user can tap it)
    .init(title: "Advanced Analysis 📊",
          body: "Scroll down and tap 'Advanced Analysis' to unlock quant stats — SMA, OLS slope, volatility, and local price extrema with a full glossary. Tap Next when you're done exploring.",
          tab: nil, arrow: .lower,
          allowsTaps: true, hasNavBar: true),

    // 9 — Portfolio (auto-switch to tab 2)
    .init(title: "Your Portfolio 💼",
          body: "See your cash balance, every stock you own, and your profit or loss on each position. Your full net worth chart lives here too.",
          tab: 2, arrow: .upper),

    // 10 — Quick Buy
    .init(title: "Quick Buy ⚡",
          body: "Enter a budget, pick an investor style — Passive (steady), Momentum (rising fast), or Value (trading at a dip) — and tap 'Buy All!' to invest in one shot.",
          tab: 2, arrow: .lower),

    // 11 — Achievements (top bar)
    .init(title: "Achievements 🏆",
          body: "Tap the trophy icon in the top bar to browse your milestones. Each achievement has five tiers from Amateur to Platinum. Claim them for bonus 💎 Gems.",
          tab: nil, arrow: .topRight),

    // 12 — Profile & Info
    .init(title: "Profile & Info",
          body: "Tap your avatar (top right) to customize your profile and settings. Tap 'Info' (top left) anytime to re-read the full FAQ.",
          tab: nil, arrow: .topLeft),

    // 13 — Done (full-screen)
    .init(title: "You're All Set! 🚀",
          body: "That's the whole app. Explore the market, build your portfolio, and see how high you can grow that $10,000. Good luck!",
          tab: 0, arrow: .none),
]

// MARK: - Overlay view

struct TutorialOverlay: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: Int

    private var step: TutorialStep { tutorialSteps[appState.tutorialStep] }
    private var idx: Int           { appState.tutorialStep }
    private var isFullScreen: Bool { step.arrow == .none }
    private var isLast: Bool       { idx == tutorialSteps.count - 1 }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {

                // Dim backdrop
                // When allowsTaps = true, passes taps through so the user can
                // interact with content beneath (stock cards, advanced dropdown).
                Color.black
                    .opacity(isFullScreen ? 0.82 : 0.64)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .allowsHitTesting(!step.allowsTaps)
                    .onTapGesture {}

                // Pulsing spotlight — always visual-only, never blocks taps
                if !isFullScreen {
                    SpotlightRing()
                        .allowsHitTesting(false)
                        .position(indicatorPos(in: geo))
                        .id(idx)
                }

                // Tutorial card
                if isFullScreen {
                    VStack {
                        Spacer()
                        fullScreenCard.padding(28)
                        Spacer()
                    }
                } else {
                    bottomCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 14)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { applyTab(for: idx) }
    }

    // MARK: - Full-screen card

    private var fullScreenCard: some View {
        VStack(spacing: 22) {
            Text(step.title)
                .font(.title.bold())
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            Text(step.body)
                .font(.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            nextButton
        }
        .padding(28)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.45), radius: 36, x: 0, y: 14)
    }

    // MARK: - Bottom card

    private var bottomCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(progressLabel.uppercased())
                    .font(.caption2.bold())
                    .tracking(1.0)
                    .foregroundColor(AppColors.textTertiary)
                Spacer()
                HStack(spacing: 5) {
                    ForEach(contentIndices, id: \.self) { i in
                        Circle()
                            .fill(i == idx
                                  ? AppColors.accent
                                  : AppColors.textTertiary.opacity(0.35))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            Text(step.title)
                .font(.title3.bold())
                .foregroundColor(AppColors.textPrimary)
            Text(step.body)
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if step.forceAction {
                actionRequiredHint
            } else {
                nextButton
            }
        }
        .padding(20)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.30), radius: 24, x: 0, y: -6)
    }

    // MARK: - Action required hint (replaces Next when forceAction = true)

    private var actionRequiredHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .font(.subheadline)
            Text("Tap a stock card above to continue")
                .font(.subheadline.bold())
        }
        .foregroundColor(AppColors.textTertiary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Next button

    private var nextButton: some View {
        Button(action: advance) {
            Text(isLast ? "Start Trading! 🚀" : "Next  →")
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isLast ? AppColors.gain : AppColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Progress helpers

    private var contentIndices: [Int] {
        tutorialSteps.indices.filter { tutorialSteps[$0].arrow != .none }
    }

    private var progressLabel: String {
        guard let pos = contentIndices.firstIndex(of: idx) else { return "" }
        return "Step \(pos + 1) of \(contentIndices.count)"
    }

    // MARK: - Navigation

    private func advance() {
        let next = idx + 1
        if next >= tutorialSteps.count {
            withAnimation(.easeInOut(duration: 0.4)) {
                appState.showTutorial = false
            }
            selectedTab = 0
            return
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            appState.tutorialStep = next
        }
        applyTab(for: next)
    }

    private func applyTab(for stepIdx: Int) {
        guard stepIdx < tutorialSteps.count,
              let tab = tutorialSteps[stepIdx].tab else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            selectedTab = tab
        }
    }

    // MARK: - Spotlight position

    private func indicatorPos(in geo: GeometryProxy) -> CGPoint {
        let w  = geo.size.width
        let h  = geo.size.height
        let si = geo.safeAreaInsets

        // Custom top bar ≈ 52pt; nav bar inside NavigationStack ≈ 44pt extra
        let topBarBottom = si.top + 52 + (step.hasNavBar ? 44 : 0)
        let botBarTop    = h - si.bottom - 68
        let contentH     = botBarTop - topBarBottom

        switch step.arrow {
        case .none:     return CGPoint(x: w / 2, y: h / 2)
        case .topLeft:  return CGPoint(x: 42, y: si.top + 26)
        case .topRight: return CGPoint(x: w - 58, y: si.top + 26)
        case .upper:    return CGPoint(x: w / 2, y: topBarBottom + contentH * 0.22)
        case .middle:   return CGPoint(x: w / 2, y: topBarBottom + contentH * 0.44)
        case .lower:    return CGPoint(x: w / 2, y: topBarBottom + contentH * 0.63)
        }
    }
}

// MARK: - Pulsing spotlight ring

private struct SpotlightRing: View {
    @State private var animating = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.accent, lineWidth: 2.5)
                .frame(width: 54, height: 54)
                .scaleEffect(animating ? 1.75 : 1.0)
                .opacity(animating ? 0.0 : 0.9)
            Circle()
                .fill(AppColors.accent.opacity(0.28))
                .frame(width: 26, height: 26)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.1).repeatForever(autoreverses: false)) {
                animating = true
            }
        }
    }
}
