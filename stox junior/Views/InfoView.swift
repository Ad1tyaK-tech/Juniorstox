import SwiftUI

struct InfoView: View {

    var body: some View {

        VStack(spacing: 20) {

            Text("About Stox")
                .font(.largeTitle.bold())

            Text("A simulation-based trading app designed to teach market behavior, trends, and risk analysis.")

                .multilineTextAlignment(.center)
                .padding()

            Text("NOT real trading — educational only.")
                .foregroundColor(.red)
                .font(.caption)

        }
        .padding()
    }
}

