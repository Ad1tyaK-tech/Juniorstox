import SwiftUI

struct SellSheet: View {

    let stock: Stock

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var shares: Int = 1

    private var sharesOwned: Int  { appState.sharesOwned[stock.realTicker] ?? 0 }
    private var buyPrice: Double  { appState.purchasePrices[stock.realTicker] ?? stock.price }
    private var proceeds: Double  { stock.price * Double(shares) }
    private var pnlPerShare: Double { stock.price - buyPrice }
    private var totalPnL: Double  { pnlPerShare * Double(shares) }
    private var pnlColor: Color   { totalPnL >= 0 ? AppColors.gain : AppColors.loss }

    private func money(_ value: Double, sign: Bool = false) -> String {
        let prefix = sign ? (value >= 0 ? "+$" : "-$") : "$"
        return "\(prefix)\(String(format: "%.2f", abs(value)))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Drag handle
            RoundedRectangle(cornerRadius: 2)
                .fill(AppColors.cardBorder)
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
                .padding(.bottom, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {

                    // Stock header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sell \(stock.company)")
                            .font(.title2.bold())
                            .foregroundColor(AppColors.textPrimary)
                        Text(stock.symbol)
                            .foregroundColor(AppColors.textSecondary)
                        HStack {
                            Text("Now: \(money(stock.price))/share")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Text("You own: \(sharesOwned)")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }

                    // Shares stepper
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How many to sell?")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)

                        HStack(spacing: 0) {
                            Button {
                                if shares > 1 { shares -= 1 }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.title3.bold())
                                    .foregroundColor(shares > 1 ? AppColors.textPrimary : AppColors.textTertiary)
                                    .frame(width: 52, height: 52)
                                    .background(AppColors.inputBackground)
                            }
                            .disabled(shares <= 1)

                            Text("\(shares)")
                                .font(.title.bold())
                                .foregroundColor(AppColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(AppColors.surfaceSecondary)

                            Button {
                                if shares < sharesOwned { shares += 1 }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title3.bold())
                                    .foregroundColor(shares < sharesOwned ? AppColors.textPrimary : AppColors.textTertiary)
                                    .frame(width: 52, height: 52)
                                    .background(AppColors.inputBackground)
                            }
                            .disabled(shares >= sharesOwned)
                        }
                        .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: shares)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppColors.cardBorder, lineWidth: 1)
                        )
                    }

                    // P&L breakdown
                    VStack(spacing: 12) {
                        SellRow(label: "Avg buy price",
                                value: money(buyPrice) + "/share")
                        SellRow(label: "Current price",
                                value: money(stock.price) + "/share")
                        SellRow(label: "Change per share",
                                value: money(pnlPerShare, sign: true),
                                color: pnlColor)
                        Rectangle()
                            .fill(AppColors.divider)
                            .frame(height: 1)
                        SellRow(label: "Shares selling",
                                value: "\(shares)")
                        SellRow(label: "Total proceeds",
                                value: money(proceeds),
                                bold: true, color: AppColors.textPrimary)
                        SellRow(label: "Net profit / loss",
                                value: money(totalPnL, sign: true),
                                bold: true, color: pnlColor)
                    }
                    .padding(16)
                    .background(AppColors.surfaceSecondary)
                    .cornerRadius(16)

                    // Action buttons
                    HStack(spacing: 12) {
                        Button("Cancel") { dismiss() }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(AppColors.inputBackground)
                            .foregroundColor(AppColors.textPrimary)
                            .font(.subheadline.bold())
                            .cornerRadius(14)

                        Button {
                            HapticsManager.sell()
                            SoundManager.shared.playKaChing()
                            appState.sellStock(stock, shares: shares)
                            dismiss()
                        } label: {
                            Label("Confirm Sell", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(AppColors.loss)
                                .foregroundColor(.white)
                                .font(.subheadline.bold())
                                .cornerRadius(14)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .background(AppColors.sheetBackground.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .onAppear {
            shares = min(shares, max(sharesOwned, 1))
        }
    }
}

private struct SellRow: View {
    let label: String
    let value: String
    var bold: Bool = false
    var color: Color = AppColors.textSecondary

    var body: some View {
        HStack {
            Text(label)
                .font(bold ? .subheadline.bold() : .subheadline)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(bold ? .subheadline.bold() : .subheadline)
                .foregroundColor(color)
        }
    }
}

#Preview {
    SellSheet(stock: sampleStocks[0])
        .environmentObject(AppState())
}
