import SwiftUI

struct AnalysisRow: View {

    let title: String
    let value: String
    var info: String? = nil
    var valueColor: Color = .white

    @State private var showInfo = false

    var body: some View {

        VStack(alignment: .leading, spacing: 6) {

            HStack {

                Text(title)
                    .foregroundColor(.gray)

                if info != nil {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showInfo.toggle()
                        }
                    } label: {
                        Image(systemName: showInfo ? "info.circle.fill" : "info.circle")
                            .font(.caption)
                            .foregroundColor(.blue.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Text(value)
                    .foregroundColor(valueColor)
                    .fontWeight(.semibold)
            }

            if showInfo, let info {
                Text(info)
                    .font(.caption)
                    .foregroundColor(.blue.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.12))
                    .cornerRadius(8)
            }
        }
    }
}
