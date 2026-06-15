import SwiftUI

struct MainDashboardView: View {

    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var showInfo = false
    @State private var showProfile = false
    @State private var showAchievements = false

    var body: some View {

        VStack(spacing: 0) {

            // TOP BAR
            HStack {

                Button("Info") {
                    showInfo = true
                }
                .foregroundColor(AppColors.accent)

                Spacer()

                HStack(spacing: 4) {
                    Text("💎")
                        .font(.subheadline)
                    Text("\(appState.gems)")
                        .font(.subheadline.bold())
                        .foregroundColor(AppColors.textPrimary)
                        .monospacedDigit()
                }

                Spacer()

                HStack(spacing: 10) {
                    Button {
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
        .preferredColorScheme(.light)
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
    }
}
