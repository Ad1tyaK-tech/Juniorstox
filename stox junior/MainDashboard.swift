import SwiftUI

struct MainDashboardView: View {

    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var showInfo = false
    @State private var showProfile = false

    var body: some View {

        VStack(spacing: 0) {

            // TOP BAR (NEW)
            HStack {

                Text("Stox")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Spacer()
                
                Button("Info") {
                    showInfo = true
                }
                .foregroundColor(.blue)
                
                
                Button {
                        showProfile = true
                    } label: {
                        ProfileButton()
                    }

            }
            .padding()
            .background(Color.black)

            Divider()

            // TABS
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
            .background(Color.black)

            // CONTENT
            ZStack {

                switch selectedTab {

                case 0:
                    HomeView()

                case 1:
                    MarketView()

                case 2:
                    PortfolioView()

                default:
                    HomeView()
                }
            }
        }
        .background(Color.black)
        .sheet(isPresented: $showInfo) {
            InfoView()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .environmentObject(appState)
        }
    }
}
