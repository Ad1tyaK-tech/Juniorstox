import SwiftUI
import Charts

struct GraphView: View {

    let closePrices: [Double]
    let trendSignal: TrendSignal

    @State private var selectedIndex: Int? = nil
    @State private var tooltipTargetX: CGFloat = 0

    private var lineColor: Color {
        switch trendSignal {
        case .bullish: return AppColors.gain
        case .bearish:  return AppColors.loss
        case .neutral:  return AppColors.highlight
        }
    }

    private var minPrice: Double { (closePrices.min() ?? 0) * 0.995 }
    private var maxPrice: Double { (closePrices.max() ?? 0) * 1.005 }

    // Rolling 20-day SMA: at each index i, average of the most recent min(20, i+1) closes
    private var smaLine: [Double] {
        closePrices.indices.map { i in
            let slice = closePrices[max(0, i - 19)...i]
            return slice.reduce(0, +) / Double(slice.count)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Chart {
                // Gradient fill under price line
                ForEach(Array(closePrices.enumerated()), id: \.offset) { index, price in
                    AreaMark(
                        x: .value("Day", index),
                        yStart: .value("Base", minPrice),
                        yEnd: .value("Price", price)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [lineColor.opacity(0.25), lineColor.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                // Price line
                ForEach(Array(closePrices.enumerated()), id: \.offset) { index, price in
                    LineMark(
                        x: .value("Day", index),
                        y: .value("Price", price),
                        series: .value("Series", "Price")
                    )
                    .foregroundStyle(lineColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }

                // Rolling 20-day SMA line
                ForEach(Array(smaLine.enumerated()), id: \.offset) { index, smaValue in
                    LineMark(
                        x: .value("Day", index),
                        y: .value("SMA", smaValue),
                        series: .value("Series", "SMA-20")
                    )
                    .foregroundStyle(AppColors.textSecondary.opacity(0.55))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .interpolationMethod(.catmullRom)
                }

                // Drag cursor: vertical rule + intersection dots
                if let idx = selectedIndex {
                    RuleMark(x: .value("Cursor", idx))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.40))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                    PointMark(
                        x: .value("Day", idx),
                        y: .value("Price", closePrices[idx])
                    )
                    .foregroundStyle(lineColor)
                    .symbolSize(70)

                    PointMark(
                        x: .value("Day", idx),
                        y: .value("SMA", smaLine[idx])
                    )
                    .foregroundStyle(AppColors.textSecondary)
                    .symbolSize(50)
                }
            }
            .chartYScale(domain: minPrice...maxPrice)
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: xAxisMarks) { value in
                    AxisGridLine()
                        .foregroundStyle(AppColors.divider)
                    AxisValueLabel {
                        if let day = value.as(Int.self) {
                            let daysAgo = (closePrices.count - 1) - day
                            Text(daysAgo == 0 ? "Today" : "\(daysAgo)d ago")
                                .font(.caption2)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(AppColors.divider)
                    AxisValueLabel {
                        if let price = value.as(Double.self) {
                            Text("$\(Int(price))")
                                .font(.caption2)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
            .frame(height: 200)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    let plotFrame = proxy.plotFrame.map { geo[$0] } ?? .zero

                    ZStack(alignment: .topLeading) {
                        // Transparent hit target covering the full chart overlay area
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let xInPlot = value.location.x - plotFrame.minX
                                        guard xInPlot >= 0, xInPlot <= plotFrame.width else {
                                            selectedIndex = nil
                                            return
                                        }
                                        if let day: Int = proxy.value(atX: xInPlot) {
                                            let clamped = max(0, min(closePrices.count - 1, day))
                                            selectedIndex = clamped
                                            // Snap tooltip x to the exact plotted position
                                            tooltipTargetX = plotFrame.minX + (proxy.position(forX: clamped) ?? xInPlot)
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            selectedIndex = nil
                                        }
                                    }
                            )

                        // Tooltip that follows the cursor horizontally, clamped inside the plot area
                        if let idx = selectedIndex {
                            let halfW: CGFloat = 68
                            let clampedX = min(max(tooltipTargetX, plotFrame.minX + halfW), plotFrame.maxX - halfW)
                            tooltipView(for: idx)
                                .fixedSize()
                                .position(x: clampedX, y: plotFrame.minY + 38)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }

            // Legend row
            HStack(spacing: 16) {
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(lineColor)
                        .frame(width: 16, height: 2)
                    Text("Price")
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary)
                }
                HStack(spacing: 5) {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(AppColors.textSecondary.opacity(0.55))
                                .frame(width: 4, height: 1.5)
                        }
                    }
                    Text("SMA-20")
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                Text("Drag to explore")
                    .font(.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(.horizontal, 4)
        }
    }

    @ViewBuilder
    private func tooltipView(for idx: Int) -> some View {
        let price = closePrices[idx]
        let smaAtPoint = smaLine[idx]
        let daysAgo = (closePrices.count - 1) - idx

        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(daysAgo == 0 ? "Today" : "\(daysAgo)d ago")
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
                Text("$\(price, specifier: "%.2f")")
                    .font(.caption.bold())
                    .foregroundColor(lineColor)
            }
            Rectangle()
                .fill(AppColors.divider)
                .frame(width: 1, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text("SMA-20")
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
                Text("$\(smaAtPoint, specifier: "%.2f")")
                    .font(.caption.bold())
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: AppColors.textPrimary.opacity(0.10), radius: 6)
    }

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
    GraphView(
        closePrices: prices,
        trendSignal: .bullish
    )
    .padding()
    .background(AppColors.background)
}
