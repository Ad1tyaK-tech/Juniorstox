import SwiftUI

struct StockCard: View {

    let stock: Stock
    var shares: Int? = nil

    var body: some View {

        HStack {

            VStack(alignment: .leading, spacing: 6) {

                Text(stock.company)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)

                HStack(spacing: 6) {
                    Text(stock.symbol)
                        .foregroundColor(AppColors.textSecondary)
                    if stock.recentlySplit {
                        Text("2:1 SPLIT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                }

                if let shares {
                    Text("\(shares) share\(shares == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {

                Text("$\(stock.price, specifier: "%.2f")")
                    .foregroundColor(AppColors.textPrimary)

                Text(
                    "\(stock.changePercent, specifier: "%.2f")%"
                )
                .foregroundColor(
                    stock.changePercent >= 0
                    ? AppColors.gain
                    : AppColors.loss
                )
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }
}
