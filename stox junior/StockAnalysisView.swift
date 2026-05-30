import SwiftUI

struct StockAnalysisView: View {

    let stock: Stock

    // Generates a kid-friendly insight based on today's actual price movement.
    private var aiInsight: String {
        let c = stock.changePercent
        switch c {
        case 6...:
            return "This stock is ZOOMING today — shooting up way faster than usual! Super exciting, but stocks that move this fast can also drop quickly. Keep your eyes on it!"
        case 3..<6:
            return "Big gains today! This stock is climbing strongly and investors are feeling great about it. It's having one of its best days this week."
        case 1..<3:
            return "Steady and climbing — this stock is quietly having a good day. Think of it like slowly going up an escalator. Not flashy, but heading the right way."
        case -1..<1:
            return "Pretty chill today — barely moving up or down. This stock is just hanging out, waiting for something exciting to happen. Could swing either way soon!"
        case -3..<(-1):
            return "A small dip today, but don't stress. Stocks go down sometimes and bounce right back. This one might just be taking a short break before heading back up."
        case -6..<(-3):
            return "Rough day for this stock. More people are selling than buying, which pushes the price down. It could recover — but worth keeping a close watch."
        default:
            return "Big drop alert! This stock is falling fast today. It might be a risky buy right now, or it could bounce back. Definitely one to watch very carefully."
        }
    }

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 20) {

                // HEADER
                VStack(alignment: .leading, spacing: 5) {

                    Text(stock.company)
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text(stock.symbol)
                        .foregroundColor(.gray)

                    Text("Current Price: $\(stock.price, specifier: "%.2f")")
                        .foregroundColor(.green)
                        .font(.title3.bold())
                }

                Divider()
                    .background(Color.gray)

                // QUICK STATS GRID
                VStack(alignment: .leading, spacing: 12) {

                    Text("Market Data")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    AnalysisRow(
                        title: "Trend",
                        value: stock.trend,
                        info: "Is this stock going up or down today? Increasing means more people are buying it, Decreasing means more people are selling."
                    )
                    AnalysisRow(
                        title: "Slope",
                        value: String(format: "%.5f", stock.slopeRate),
                        info: "How fast the price is moving. A bigger positive number means it's rising quickly. A negative number means it's dropping. Think of it like the steepness of a hill."
                    )
                    AnalysisRow(
                        title: "Max Price",
                        value: String(format: "$%.2f", stock.maxima),
                        info: "The highest price this stock hit today — its peak moment. If the current price is close to this, it's near its best point of the day."
                    )
                    AnalysisRow(
                        title: "Min Price",
                        value: String(format: "$%.2f", stock.minima),
                        info: "The lowest price today — the cheapest it's been. If the current price is close to this, it might be a more affordable entry point."
                    )
                    AnalysisRow(
                        title: "Support Floor",
                        value: String(format: "$%.2f", stock.floor),
                        info: "Yesterday's closing price. This acts like a baseline — if today's price is above it, the stock is doing better than yesterday!"
                    )
                    AnalysisRow(
                        title: "Daily Change",
                        value: String(format: "%.5f%%", stock.changePercent),
                        info: "How much the price has changed today compared to yesterday, shown as a percentage. Positive means it grew, negative means it shrank."
                    )
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                // AI INSIGHT SECTION
                VStack(alignment: .leading, spacing: 10) {

                    Text("AI Insight")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text(aiInsight)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)

                Spacer()
            }
            .padding()
        }
        .background(Color.black)
    }
}
