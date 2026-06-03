import SwiftUI
import Charts

struct GraphView: View {

    let closePrices: [Double]
    let sma: Double
    let trendSignal: TrendSignal

    private var lineColor: Color {
        switch trendSignal {
        case .bullish: return .green
        case .bearish:  return .red
        case .neutral:  return .yellow
        }
    }

    private var minPrice: Double { (closePrices.min() ?? 0) * 0.995 }
    private var maxPrice: Double { (closePrices.max() ?? 0) * 1.005 }

    var body: some View {
        Chart {
            // Gradient fill under the line
            ForEach(Array(closePrices.enumerated()), id: \.offset) { index, price in
                AreaMark(
                    x: .value("Day", index),
                    yStart: .value("Base", minPrice),
                    yEnd: .value("Price", price)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [lineColor.opacity(0.3), lineColor.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }

            // Price line
            ForEach(Array(closePrices.enumerated()), id: \.offset) { index, price in
                LineMark(
                    x: .value("Day", index),
                    y: .value("Price", price)
                )
                .foregroundStyle(lineColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }

            // 20-day SMA reference line
            RuleMark(y: .value("20-Day SMA", sma))
                .foregroundStyle(Color.white.opacity(0.45))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("SMA  $\(sma, specifier: "%.2f")")
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.6))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
        }
        .chartYScale(domain: minPrice...maxPrice)
        .chartXAxis {
            AxisMarks(values: xAxisMarks) { value in
                AxisGridLine()
                    .foregroundStyle(Color.white.opacity(0.08))
                AxisValueLabel {
                    if let day = value.as(Int.self) {
                        let daysAgo = (closePrices.count - 1) - day
                        Text(daysAgo == 0 ? "Today" : "\(daysAgo)d ago")
                            .font(.caption2)
                            .foregroundStyle(Color.gray)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(Color.white.opacity(0.08))
                AxisValueLabel {
                    if let price = value.as(Double.self) {
                        Text("$\(Int(price))")
                            .font(.caption2)
                            .foregroundStyle(Color.gray)
                    }
                }
            }
        }
        .frame(height: 200)
    }

    // Four evenly spaced tick marks across the available days
    private var xAxisMarks: [Int] {
        let last = max(0, closePrices.count - 1)
        guard last > 0 else { return [0] }
        return [0, last / 3, (last * 2) / 3, last]
    }
}

#Preview {
    let prices: [Double] = (0..<90).map { i -> Double in
        let x = Double(i)
        return 150.0 + sin(x * 0.15) * 12.0 + x * 0.3
    }
    let smaValue: Double = prices.suffix(20).reduce(0.0, +) / 20.0
    GraphView(
        closePrices: prices,
        sma: smaValue,
        trendSignal: .bullish
    )
    .padding()
    .background(Color.black)
}
