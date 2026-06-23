import SwiftUI

struct InfoView: View {

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    aboutHeader
                    faqSection(title: "General",      icon: "info.circle.fill",   items: generalFAQ)
                    faqSection(title: "Home",          icon: "house.fill",          items: homeFAQ)
                    faqSection(title: "Market",        icon: "chart.bar.fill",      items: marketFAQ)
                    faqSection(title: "Portfolio",     icon: "briefcase.fill",      items: portfolioFAQ)
                    faqSection(title: "Achievements",  icon: "trophy.fill",         items: achievementsFAQ)
                    disclaimer
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("Info & FAQ")
        }
    }

    // MARK: - About header

    private var aboutHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About Stox Junior")
                .font(.title2.bold())
                .foregroundColor(AppColors.textPrimary)
            Text("A simulation-based trading app designed to teach market behavior, trends, and risk analysis — no real money involved.")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("NOT real trading — educational only.")
                .font(.caption.bold())
                .foregroundColor(AppColors.loss)
                .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Section builder

    private func faqSection(title: String, icon: String, items: [FAQItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(AppColors.accent)
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                    FAQRow(item: item, showDivider: idx < items.count - 1)
                }
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Disclaimer

    private var disclaimer: some View {
        Text("Prices may be delayed up to 15 minutes. Stox Junior is for learning purposes only and does not constitute financial advice.")
            .font(.caption)
            .foregroundColor(AppColors.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }

    // MARK: - FAQ content

    private let generalFAQ: [FAQItem] = [
        FAQItem(
            question: "What is Stox Junior?",
            answer: "Stox Junior lets you practice buying and selling real stocks with fake money. You learn how markets work — gains, losses, trends, and risk — without any real financial risk."
        ),
        FAQItem(
            question: "How much money do I start with?",
            answer: "Every account starts with $10,000 in virtual cash. Your goal is to grow it as high as possible by making smart trades."
        ),
        FAQItem(
            question: "What are Gems (💎)?",
            answer: "Gems are your in-app reward currency. Earn them by completing Daily Challenges and claiming Achievement tiers. They track how active and skilled you've become."
        ),
        FAQItem(
            question: "Is any real money involved?",
            answer: "No. Everything in Stox Junior is 100% simulated. You cannot lose or gain real money."
        ),
    ]

    private let homeFAQ: [FAQItem] = [
        FAQItem(
            question: "What is the Daily Challenge?",
            answer: "Each day you get a short trading goal — like making a trade or buying a specific type of stock. Complete it to earn 5 💎. The challenge resets every day at midnight."
        ),
        FAQItem(
            question: "How do I claim my Daily Challenge reward?",
            answer: "Finish the challenge task first. The 'Claim' button turns active once the goal is met — tap it to collect your 5 💎 before the day resets."
        ),
        FAQItem(
            question: "What is the Net Worth card?",
            answer: "It shows your total account value: your available cash plus the current market value of all your stocks. Tap it to jump to your full Portfolio history and chart."
        ),
        FAQItem(
            question: "What are Top Gainer, Top Loser, and Steadiest?",
            answer: "These highlight today's standout stocks. Top Gainer rose the most, Top Loser fell the most, and Steadiest changed the least. Tap any card to open a full analysis."
        ),
    ]

    private let marketFAQ: [FAQItem] = [
        FAQItem(
            question: "What are sectors?",
            answer: "Stocks are grouped into industries: Big Tech, Chip Makers, Shopping, Cars & Energy, Money & Crypto, and Gaming. Tap a sector header to expand or collapse its list."
        ),
        FAQItem(
            question: "How do I buy a stock?",
            answer: "Swipe right on any stock card to reveal the Buy button, or tap a card to open its full analysis page where you can buy from there too."
        ),
        FAQItem(
            question: "Are these real stock prices?",
            answer: "Yes — prices are pulled from live market data but may be delayed up to 15 minutes. Pull down on the Market page to force a refresh."
        ),
        FAQItem(
            question: "What does the % change mean?",
            answer: "It shows how much the stock's price has moved today compared to yesterday's closing price. Green means up; red means down."
        ),
        FAQItem(
            question: "Why can't I see some sector groups?",
            answer: "A sector only appears when at least one of its stocks is loaded from the market. If a sector is missing, try pulling down to refresh the page."
        ),
    ]

    private let portfolioFAQ: [FAQItem] = [
        FAQItem(
            question: "What is my Cash Balance?",
            answer: "The money you have available to spend on new stocks. Buying deducts from it; selling adds back to it."
        ),
        FAQItem(
            question: "How do I sell a stock?",
            answer: "Swipe left on a stock in your holdings to reveal the Sell button. A sheet appears where you can choose how many shares to sell."
        ),
        FAQItem(
            question: "What is Quick Buy?",
            answer: "Quick Buy lets you put a set budget to work in one tap. Enter a dollar amount, pick an investor mode, and the app suggests the best-matching stocks — then tap 'Buy All!' to execute instantly."
        ),
        FAQItem(
            question: "What are the investor modes?",
            answer: "Passive targets steady growers with low daily swings — good for a 'set it and forget it' approach. Momentum chases the fastest-rising stocks right now. Value finds stocks currently dipping below their usual low, betting on a bounce back."
        ),
        FAQItem(
            question: "What is P&L (profit and loss)?",
            answer: "P&L is the difference between what you paid for your shares and what they're worth at the current price. Green means you're up on that holding; red means you're down."
        ),
        FAQItem(
            question: "What does the net worth chart show?",
            answer: "It plots your total account value over time. The dashed reference line marks your $10,000 starting balance so you can quickly see your overall progress at a glance."
        ),
    ]

    private let achievementsFAQ: [FAQItem] = [
        FAQItem(
            question: "What are Achievements?",
            answer: "Achievements are long-term goals that reward you with 💎 for hitting milestones — like making your first trade, growing your portfolio, or completing multiple daily challenges."
        ),
        FAQItem(
            question: "What are the achievement tiers?",
            answer: "Each achievement has five tiers in order: Amateur → Bronze → Silver → Gold → Platinum. You must claim a tier before the next one unlocks."
        ),
        FAQItem(
            question: "How do I claim an achievement reward?",
            answer: "Once your progress hits the tier's threshold, a glowing 'Claim' button appears on that card. Tap it to collect your 💎 and unlock the next tier."
        ),
        FAQItem(
            question: "What do the colored dots at the bottom of a card mean?",
            answer: "They show your tier trail. A filled dot with a checkmark = already claimed. A star dot = ready to claim now. A faint dot = in progress but not there yet."
        ),
        FAQItem(
            question: "Why do some tiers appear hidden?",
            answer: "Locked tiers are hidden on purpose — you only see what you can realistically reach. Once you claim a tier, the next one becomes visible with its progress bar."
        ),
    ]
}

// MARK: - Supporting types

private struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

private struct FAQRow: View {
    let item: FAQItem
    let showDivider: Bool
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expanded.toggle()
                }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Text(item.question)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppColors.textTertiary)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                        .padding(.top, 2)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)

            if expanded {
                Text(item.answer)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if showDivider {
                Divider()
                    .padding(.leading, 14)
            }
        }
    }
}
