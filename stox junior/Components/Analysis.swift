import SwiftUI

struct AnalysisRow: View {

    let title: String
    let value: String
    var info: String? = nil
    var valueColor: Color = AppColors.textPrimary

    @State private var showInfo = false

    var body: some View {

        VStack(alignment: .leading, spacing: 6) {

            if info != nil {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showInfo.toggle() }
                } label: {
                    rowContent
                }
                .buttonStyle(.plain)
            } else {
                rowContent
            }

            if showInfo, let info {
                Text(info)
                    .font(.caption)
                    .foregroundColor(AppColors.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(AppColors.accent.opacity(0.10))
                    .cornerRadius(8)
            }
        }
    }

    private var rowContent: some View {
        HStack {
            Text(title)
                .foregroundColor(AppColors.textSecondary)

            if info != nil {
                Image(systemName: showInfo ? "info.circle.fill" : "info.circle")
                    .font(.caption)
                    .foregroundColor(AppColors.accent)
            }

            Spacer()

            Text(value)
                .foregroundColor(valueColor)
                .fontWeight(.semibold)
        }
        .contentShape(Rectangle())
    }
}
