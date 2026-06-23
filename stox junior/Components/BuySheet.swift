import SwiftUI

struct BuySheet: View {

    let stock: Stock

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var shares: Int = 1

    private var totalCost: Double { stock.price * Double(shares) }
    private var remaining: Double { appState.cashBalance - totalCost }
    private var canAfford: Bool { totalCost <= appState.cashBalance }
    private var canAddShare: Bool { stock.price * Double(shares + 1) <= appState.cashBalance }

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
                        Text("Buy \(stock.company)")
                            .font(.title2.bold())
                            .foregroundColor(AppColors.textPrimary)
                        Text(stock.symbol)
                            .foregroundColor(AppColors.textSecondary)
                        Text("$\(stock.price, specifier: "%.2f") per share")
                            .font(.subheadline)
                            .foregroundColor(AppColors.gain)
                    }

                    // Shares stepper
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How many shares?")
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
                                if canAddShare { shares += 1 }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title3.bold())
                                    .foregroundColor(canAddShare ? AppColors.textPrimary : AppColors.textTertiary)
                                    .frame(width: 52, height: 52)
                                    .background(AppColors.inputBackground)
                            }
                            .disabled(!canAddShare)
                        }
                        .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: shares)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppColors.cardBorder, lineWidth: 1)
                        )
                    }

                    // Cost summary card
                    VStack(spacing: 12) {
                        CostRow(label: "Price per share", value: String(format: "$%.2f", stock.price))
                        CostRow(label: "Shares", value: "\(shares)")
                        Rectangle()
                            .fill(AppColors.divider)
                            .frame(height: 1)
                        CostRow(
                            label: "Total cost",
                            value: String(format: "$%.2f", totalCost),
                            bold: true,
                            color: canAfford ? AppColors.textPrimary : AppColors.loss
                        )
                        CostRow(
                            label: "Cash after purchase",
                            value: String(format: "$%.2f", remaining),
                            color: canAfford ? AppColors.gain : AppColors.loss
                        )
                    }
                    .padding(16)
                    .background(AppColors.surfaceSecondary)
                    .cornerRadius(16)

                    if !canAfford {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColors.warning)
                                .font(.caption)
                            Text("Not enough cash for this purchase.")
                                .font(.caption)
                                .foregroundColor(AppColors.warning)
                        }
                    }

                    // Action buttons
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(AppColors.inputBackground)
                        .foregroundColor(AppColors.textPrimary)
                        .font(.subheadline.bold())
                        .cornerRadius(14)

                        Button {
                            HapticsManager.buy()
                            SoundManager.shared.playKaChing()
                            appState.buyStock(stock, shares: shares)
                            dismiss()
                        } label: {
                            Label("Confirm Buy", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(canAfford ? AppColors.gain : AppColors.inputBackground)
                                .foregroundColor(canAfford ? .white : AppColors.textTertiary)
                                .font(.subheadline.bold())
                                .cornerRadius(14)
                        }
                        .disabled(!canAfford)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "graduationcap.fill")
                            .font(.caption2)
                        Text("Simulated · No real money involved")
                            .font(.caption2)
                    }
                    .foregroundColor(AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .background(AppColors.sheetBackground.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

private struct CostRow: View {
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
    BuySheet(stock: sampleStocks[0])
        .environmentObject(AppState())
}
