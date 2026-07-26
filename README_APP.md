# Stox Junior — iOS Stock Market Simulator

**Built by Aditya Kiran · SwiftUI · iOS 17+**

> [YOUR ONE-LINE HOOK: What is this app in a single sentence? e.g. "A stock market simulator that makes investing approachable for kids — without the noise of real money or real tickers."]

---

## The Idea

<!-- Answer these three questions in your own words: -->
<!-- 1. What frustrated you or what gap did you notice that made you want to build this? -->
<!-- 2. Who is it actually for? (younger sibling? a younger version of you?) -->
<!-- 3. What does "success" look like — what would a kid get out of using this? -->

[YOUR WORDS HERE — this is the most important section. Be personal and specific.]

---

## What the App Does (User's Perspective)

You open the app to a personalized **Home screen** showing your cash balance, a live net worth chart, today's top gainer/loser/steadiest stock, and a daily challenge to complete. From there you can:

- Browse the **Market** — 10 stocks across 5 sectors (Big Tech, Chip Makers, Shopping, Cars & Energy, Money & Crypto, Gaming), each with a price, change %, trend indicator, and a swipe-to-buy shortcut
- Tap any stock to open **deep analysis** — a 90-day interactive price chart, 20-day moving average, trend signal (Bullish / Neutral / Bearish), annualized volatility, OLS regression slope, support/resistance levels, and insight cards
- **Buy and sell** shares with a full sheet showing cost breakdown, shares owned, and average purchase price
- Watch your **Portfolio** grow — tracks holdings, unrealized gain/loss per stock, and overall net worth over time on a live chart
- Complete **Daily Challenges** to earn gems (e.g. "open advanced analysis for 3 stocks", "improve net worth by 2% today", "spend $2,000 on stocks")
- Unlock **Achievements** across 12 categories with 5 tiers each (Amateur → Bronze → Silver → Gold → Platinum), rewarding specific trading behaviors
- Spend gems in the **Avatar Shop** on 36 unique characters across three tiers
- View full **Trade History** and all past snapshots
- Set up and recover your account through a complete **Auth flow** (sign up, log in, forgot password)

---

## The Fictional Market — A Design Decision I'm Proud Of

Real stock tickers (AAPL, NVDA, TSLA) carry baggage — news cycles, parent recognition, real anxiety. I replaced them with fictional aliases:

| Real Ticker | Display Symbol | Company Name | Sector |
|-------------|---------------|--------------|--------|
| AAPL | PEA | Pear | Big Tech |
| MSFT | MDS | Macrodense | Big Tech |
| GOOG | GEG | Geggol | Big Tech |
| META | ATE | Atem Systems | Big Tech |
| NVDA | NMV | Nmovia | Chip Makers |
| AMD | SMD | Strong Mini Devices | Chip Makers |
| AMZN | BRZ | Bravozon | Shopping |
| TSLA | EIN | Einstein | Cars & Energy |
| COIN | DST | Dollarstand | Money & Crypto |
| RBLX | PLY | Playbit | Gaming |

<!-- Why did this matter to you? What does this design choice say about how you thought about the user? -->
[YOUR WORDS HERE — explain the reasoning behind this decision in your own voice]

---

## Architecture

```
App/
  AppState.swift              — central ObservableObject; owns all published state
  AppState+Portfolio.swift    — buy/sell logic, net worth calc, market refresh
  AppState+Challenge.swift    — daily challenge tracking and gem claiming
  AppState+Achievements.swift — tracks 12 behavior counters, tier unlock logic
  AppState+Auth.swift         — sign-in, session restore, sign-out
  AppState+Persistence.swift  — saves/loads full account state to Supabase
  AppState+Settings.swift     — avatar, color scheme, haptics, cellular toggle

Auth/                         — Welcome → Login / Create Account / Forgot Password

Views/
  HomeView.swift              — dashboard: net worth, daily challenge, market highlights
  MarketView.swift            — full stock list with swipe-to-buy cards
  PortfolioView.swift         — holdings, gain/loss per position, net worth history
  HistoryView.swift           — full trade and snapshot log
  AchievementsView.swift      — 12 achievement cards with tier progress
  ProfileView.swift           — avatar, settings, portfolio reset, sign out

Components/
  StockCard.swift             — reusable price card used in market and home views
  SwipeRevealCard.swift       — swipe-left-to-buy gesture on market cards
  BuySheet.swift / SellSheet.swift — transaction sheets with quantity picker
  Analysis.swift              — the full 90-day analysis sheet (chart + stats)
  InsightCard.swift           — individual stat tiles (volatility, slope, SMA spread…)

Services/
  StockService.swift          — deterministic synthetic price generation
  MarketService.swift         — Supabase actor; reads/writes shared market_prices table
  AccountService.swift        — Supabase CRUD for user accounts
  PriceAnalyzer.swift         — pure math engine: SMA, OLS, volatility, extrema
  HapticsManager.swift        — haptic feedback on trades and achievements
  SoundManager.swift          — celebration sounds

Models/
  StockModel.swift            — Stock struct + fictional alias map + sample data
  UserAccount.swift           — Codable account saved to Supabase
  Achievement.swift           — 12 AchievementDef entries, 5-tier thresholds, gem rewards
  DailyChallenge.swift        — 10 challenges, date-seeded daily picker, balance scaling
  AvatarData.swift            — 36 AvatarItem entries across 3 DiceBear style tiers
  PriceAnalysis.swift         — value type holding all computed stats for one stock
```

---

## The Price Engine

This is the most technically interesting part of the project. Every price is **generated in code** — there is no live market data feed. The design goal was: all users see the same prices on the same day, prices feel realistic, and no two days look the same.

### How a price is built each day

**1. Seeded base return** (same for all users)
A Linear Congruential Generator hashed with `ticker + date` feeds a Box-Muller transform to produce a Gaussian daily return with σ = 1.5% — roughly realistic for large-cap equities. Every user on the same day gets the same direction and magnitude from this step.

**2. 5-day trailing momentum**
The average of the past 5 seeded returns gets amplified (×10 on the displayed change, ×2.5 on price). A stock that moved up for 5 consecutive days gets a significant push in the same direction. This makes trending stocks actually feel like they have momentum.

**3. Seeded daily opening amplifier** *(added this summer)*
A separate LCG stream keyed on `ticker + date + "dawn"` produces a uniform roll in [-10, 10]. That roll gets scaled by a **volatility multiplier** based on the stock's price tier:

```
volatilityMultiplier = clamp(200 / basePrice, 0.5, 5.0)
```

| Stock | Base Price | Multiplier | Roll of 10 → |
|-------|-----------|------------|--------------|
| PLY (Playbit) | $42 | 4.76 | ~48% swing |
| SMD (Strong Mini) | $130 | 1.54 | ~15% swing |
| PEA (Pear) | $213 | 0.94 | ~9% swing |
| MDS (Macrodense) | $412 | 0.49 → 0.5 | ~5% swing |
| NMV (Nmovia) | $891 | 0.22 → 0.5 | ~5% swing |

This means a cheap volatile stock can open up 40% on an exciting day while a large-cap barely moves — mimicking how real small-caps vs. mega-caps behave differently at market open.

**4. Intraday noise**
A small random tick (±a few dollars, biased toward the day's trend direction) is added on every refresh so the market feels alive between opens.

**5. Display amplification**
All changes are amplified 3× for display so kids see dramatic-looking numbers — a 1.5% real move shows as ~4.5%. This is intentional: the goal is engagement, not realism.

### Why deterministic pricing matters

<!-- Explain this in your own words — it's a subtle but smart architectural choice -->
[YOUR WORDS HERE — why did you want all users to see the same prices? What would happen if you didn't?]

---

## Engagement Systems

### Daily Challenges
One challenge is assigned per day, selected deterministically by `(year × 400 + month × 31 + day) % 10` so everyone gets the same challenge. Dollar amounts scale to the user's starting balance. Examples:
- "Open the advanced analysis for 3 different stocks" (target: 3)
- "Improve your net worth by 2% today"
- "Buy 5 stocks from the technology sector"
- "Sell a stock that is rising today"

Completing a challenge awards **5 gems**. The claim button stays visible all day.

### Achievements
12 achievement categories, each with 5 tiers (Amateur → Bronze → Silver → Gold → Platinum). Gem rewards increase with tier: 10 / 30 / 60 / 100 / 200.

| Achievement | What it tracks |
|-------------|---------------|
| Diverse Portfolio | Shares owned across 8+ different tickers |
| Investor | Most shares held in a single ticker at once |
| Gambler | Shares bought in stocks with ±2% change |
| Intellectual | Times the advanced analysis view was opened |
| Spontaneous | Times Quick Buy was used |
| Safe Investor | Shares bought in low-volatility steady stocks |
| Momentum Buyer | Shares bought in fast-rising stocks (+2%) |
| Bargainer | Shares bought near a stock's floor price |
| Profit Taker | Profitable sell transactions |
| Loss Cutter | Loss-taking sell transactions |
| Market Addict | App opens within rolling time windows |
| Loyalty | Shares held in one stock for 5 / 15 / 30 / 100 / 250+ days |

### Avatar Shop
36 characters across 3 tiers, each generated by the DiceBear API in a different art style:

| Tier | Style | Cost | Examples |
|------|-------|------|---------|
| Animal Pals | fun-emoji | 30 💎 | Tired Dog, Scream Fox, Hot Lion… |
| Legends | pixel-art | 100 💎 | Dragon Whisperer, Phoenix Shifter, Vampire Hunter… |
| Heroes | adventurer | 500 💎 | Green Witch, Punk Kid, Geek Supreme… |

---

## Technical Choices Worth Mentioning

- **`actor` for network calls** — `MarketService` is declared as a Swift `actor`, preventing data races when multiple async tasks try to read or write market prices concurrently
- **No Combine** — all async work uses Swift's structured concurrency (`async/await`, `Task`) instead of Combine publishers; cleaner to reason about and debug
- **Pure math layer** — `PriceAnalyzer` is a stateless struct with only static methods; given the same `[Double]` input it always returns the same output, making every formula trivially testable
- **Shared market state via Supabase** — when any user refreshes, they write new prices to a shared `market_prices` table; the next user to open the app reads those prices. One upsert per refresh keeps costs near zero
- **UserDefaults caching** — 90-day price histories are expensive to compute; they're cached by `(ticker, date)` key so they're only generated once per calendar day per device
- **LCG seeding for determinism** — the same 64-bit LCG hash function is used in three places (daily return, open amplifier, daily challenge selection) to ensure reproducibility without a central clock server

---

## What I'm Most Proud Of

<!-- Be specific and honest — these should be things you actually figured out yourself, not things that sound impressive. -->
<!-- "I'm proud that I figured out X because it taught me Y" is stronger than "I implemented Z." -->

1. [YOUR WORDS HERE]
2. [YOUR WORDS HERE]
3. [YOUR WORDS HERE]

---

## Hardest Problems I Hit

<!-- Real obstacles make this come alive for a reader. What actually broke? What confused you for days? -->
<!-- Don't just say "networking was hard" — say what specifically failed and what you learned from fixing it. -->

### [Name the problem yourself]
> What happened:
> How I figured it out:

### [Name the problem yourself]
> What happened:
> How I figured it out:

---

## What I'd Build Next

<!-- Shows you think beyond the immediate task. Be honest — what would actually make this better? -->

- 
- 
- 

---

## If You Want to Run It

```bash
git clone <your-repo-url>
cp "stox junior/Config/Secrets.example.swift" "stox junior/Config/Secrets.swift"
# Add your Supabase project URL and anon key to Secrets.swift
open Juniorstox.xcodeproj
```

Requires Xcode 15+, iOS 17+, and a Supabase project with a `market_prices` table.
The schema is documented at the top of `MarketService.swift`.

---

## Screenshots

<!-- Drop in 3–5 screenshots. Home, Market, Analysis, Portfolio, Achievements are the strongest screens to show. -->

---

*Built summer 2026 as a portfolio project — [YOUR CONTEXT: why this project, why now, what you were learning]*
