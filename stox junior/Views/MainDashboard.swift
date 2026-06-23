import SwiftUI

struct MainDashboardView: View {

    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var showInfo = false
    @State private var showProfile = false
    @State private var showAchievements = false

    // Gem burst
    @State private var gemBurstVisible = false
    @State private var gemBurstFloating = false
    @State private var gemBurstCount = 0

    // Streak popup
    @State private var showStreakPopup = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {

                // TOP BAR
                HStack {

                    Button("Info") {
                        HapticsManager.click()
                        showInfo = true
                    }
                    .foregroundColor(AppColors.accent)

                    Spacer()

                    HStack(spacing: 10) {
                        if appState.currentStreak >= 1 {
                            HStack(spacing: 3) {
                                Text("🔥")
                                    .font(.subheadline)
                                Text("\(appState.currentStreak)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(AppColors.textPrimary)
                                    .monospacedDigit()
                            }
                        }
                        HStack(spacing: 4) {
                            Text("💎")
                                .font(.subheadline)
                            Text("\(appState.gems)")
                                .font(.subheadline.bold())
                                .foregroundColor(AppColors.textPrimary)
                                .monospacedDigit()
                        }
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        Button {
                            HapticsManager.click()
                            showAchievements = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "trophy.fill")
                                    .font(.title3)
                                    .foregroundColor(AppColors.highlight)
                                if appState.hasClaimableAchievements {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 9, height: 9)
                                        .offset(x: 5, y: -4)
                                }
                            }
                        }
                        Button {
                            HapticsManager.click()
                            showProfile = true
                        } label: {
                            ProfileButton()
                        }
                    }

                }
                .padding()
                .background(AppColors.surface)

                Divider()

                // SWIPEABLE CONTENT
                TabView(selection: $selectedTab) {

                    HomeView(selectedTab: $selectedTab)
                        .tag(0)

                    MarketView()
                        .tag(1)

                    PortfolioView()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Divider()

                // BOTTOM TAB BAR
                HStack {

                    DashboardTabButton(title: "Home", selected: selectedTab == 0) {
                        selectedTab = 0
                    }

                    DashboardTabButton(title: "Market", selected: selectedTab == 1) {
                        selectedTab = 1
                    }

                    DashboardTabButton(title: "Portfolio", selected: selectedTab == 2) {
                        selectedTab = 2
                    }
                }
                .padding()
                .background(AppColors.surface)
            }
            .background(AppColors.background)

            // Gem burst — pill springs in at center then flies up toward the gem counter
            if gemBurstVisible {
                Text("+\(gemBurstCount) 💎")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.48, green: 0.18, blue: 0.92).opacity(0.92))
                            .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
                    )
                    .offset(y: gemBurstFloating ? -340 : 0)
                    .opacity(gemBurstFloating ? 0 : 1)
                    .scaleEffect(gemBurstFloating ? 0.6 : 1.0)
                    .allowsHitTesting(false)
                    .zIndex(9)
            }

            // Streak popup — fills screen, then shrinks to top bar
            if showStreakPopup {
                streakBanner
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.08, anchor: .center).combined(with: .opacity),
                        removal: .scale(scale: 0.02, anchor: .top).combined(with: .opacity).combined(with: .move(edge: .top))
                    ))
                    .zIndex(10)
            }

            // First-time tutorial — only shown on new account creation
            if appState.showTutorial {
                TutorialOverlay(selectedTab: $selectedTab)
                    .transition(.opacity)
                    .zIndex(20)
            }
        }
        .preferredColorScheme(appState.preferredColorScheme)
        .task {
            await appState.refreshMarket()
        }
        .sheet(isPresented: $showInfo) {
            InfoView()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
                .environmentObject(appState)
        }
        .onChange(of: appState.gems) { oldVal, newVal in
            let diff = newVal - oldVal
            guard diff > 0 else { return }
            gemBurstCount = diff
            gemBurstFloating = false
            gemBurstVisible = true
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.55)) {
                gemBurstFloating = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                gemBurstVisible = false
                gemBurstFloating = false
            }
        }
        .onChange(of: appState.currentStreak) { oldVal, newVal in
            guard newVal > oldVal, newVal >= 2 else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                showStreakPopup = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                    showStreakPopup = false
                }
            }
        }
    }

    // MARK: - Streak Banner

    @ViewBuilder
    private var streakBanner: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.45, blue: 0.0), Color(red: 1.0, green: 0.68, blue: 0.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("🔥")
                    .font(.system(size: 88))
                Text("\(appState.currentStreak) Day Streak!")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)
                Text("+1 💎 streak bonus")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white.opacity(0.88))
            }
        }
    }
}
