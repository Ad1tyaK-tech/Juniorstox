import SwiftUI
import SwiftData

@main
struct StoxApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: UserAccount.self)
    }
}
