import SwiftUI

struct DashboardTabButton: View {

    let title: String
    let selected: Bool

    let action: () -> Void

    var body: some View {

        Button(action: action) {

            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(selected ? .white : AppColors.textSecondary)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    selected
                    ? AppColors.accent
                    : AppColors.surfaceSecondary
                )
                .cornerRadius(12)
        }
    }
}
