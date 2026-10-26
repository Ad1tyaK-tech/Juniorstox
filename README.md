# stox junior — App Overview

> A kid-friendly stock market simulator built in SwiftUI, backed by Supabase.
> All prices are **fully simulated** — no real money, no real brokerage connection.

---

## Table of Contents
1. [Concept & Purpose](#1-concept--purpose)
2. [Architecture Overview](#2-architecture-overview)
3. [Authentication & Persistence](#3-authentication--persistence)
4. [Stock & Price Engine](#4-stock--price-engine)
5. [Core Trading Mechanics](#5-core-trading-mechanics)
6. [User Interface](#6-user-interface)
7. [Gamification Systems](#7-gamification-systems)
8. [Settings & Personalization](#8-settings--personalization)
9. [Services Layer](#9-services-layer)
10. [Personal Reflections](#10-personal-reflections)

---

## 1. Concept & Purpose

stox junior teaches kids how the stock market works through simulated trading with **fictional company names** mapped to real ticker behavior. Real tickers (AAPL, NVDA, etc.) are used internally as price seeds, but users only ever see playful aliases:

| Real Ticker | Display Symbol | Display Name |
|---|---|---|
| AAPL | PEA | Pear |
| NVDA | NMV | Nmovia |
| TSLA | EIN | Einstein |
| GOOG | GEG | Geggol |
| META | ATE | Atem Systems |
| AMZN | BRZ | Bravozon |
| MSFT | MDS | Macrodense |
| AMD | SMD | Strong Mini Devices |
| COIN | DST | Dollarstand |
| RBLX | PLY | Playbit |

Stocks are organized into 6 sectors: **Big Tech, Chip Makers, Shopping, Cars & Energy, Money & Crypto, Gaming.**

---

## 2. Architecture Overview

- **Entry point:** `StoxApp` → `RootView` → auth-state switch → `MainDashboardView`
- **State management:** Single `@ObservableObject` class `AppState` injected as `@EnvironmentObject` throughout the view tree. Broken into 5 extensions: `+Portfolio`, `+Challenge`, `+Achievements`, `+Auth`, `+Settings`
- **Concurrency:** All UI state lives on `@MainActor`. `AccountService` is a Swift `actor` for thread-safe Supabase calls. Background tasks use `async/await` — no Combine.
- **Data model:** `UserAccount` is a plain `Codable` struct persisted entirely in Supabase. Sub-state (challenge, achievements, settings) is stored as nested JSON columns (`daily_challenge_json`, `achievements_json`, `settings_json`) for easy schema evolution.
- **Monetary precision:** All balances are stored as **integer cents** (`cashBalance: Int`) to avoid floating-point drift. Display conversions divide by 100.

---

## 3. Authentication & Persistence

### Auth Flow
```
Welcome → Login / Create Account → (new users) Privacy Consent → MainDashboard
       ↘ Forgot Password ↗
```
- Session persisted in `UserDefaults` (just the username). On next launch, the account is re-fetched from Supabase; on failure, the user is returned to the welcome screen.
- Passwords are hashed client-side with **SHA-256** (via CryptoKit) before being stored. The server never sees plaintext passwords.
- Login rate limiting is handled by `LoginRateLimiter`.
- Account recovery: user links a "keycode" (any text, often an email) stored inside `settingsJSON`. Password reset searches all accounts for a matching keycode.

### Persistence Strategy
- Every trade, achievement, setting, or challenge event triggers `saveToAccount()`, which debounces writes using a `pendingSaveTask` (cancels the previous task before starting a new one).
- Net worth snapshots are taken hourly via a background `Task` loop and on every buy/sell. A `catchUpSnapshots()` call on `scenePhase == .active` back-fills any hours the app was closed.

---

## 4. Stock & Price Engine

### Synthetic Price Generation (`StockService`)

This is the most technically interesting part of the app. All prices are algorithmically generated — **no API calls to financial data providers.**

**Compounding from an epoch:**
Every price is computed by compounding a seeded daily return from `priceEpoch = "2025-01-01"` forward to today. This means prices have genuine long-term drift and history.

**Seeded randomness (LCG + Box-Muller):**
```
seededDailyReturn(ticker, date) → N(drift=+0.03%/day, vol=2.2%/day)
```
The seed is derived from `ticker + dateString`, so every user sees the **same price direction on the same calendar day** — the market is shared.

**Price components layered on top of the compounded base:**
| Component | Description |
|---|---|
| `seededIntradayTick` | Stable ±1.5% nudge — same across all hourly refreshes |
| `seededOpenAmplifier` | Opening roll ±10, scaled by `volatilityMultiplier` (cheap stocks swing harder) |
| `seededShockImpact` | 10% chance of ±6% jolt per (ticker, date) |
| `momentum5d` | 5-day trailing average return amplified ×2.5 — creates believable trends |
| `randomTick` | Small random tick (capped ±$5) added each refresh so the price visibly moves |

**Stock splits:**
When a compounded price exceeds $500, a **2:1 split** fires: price halves, `splitMultiplier` doubles. The app detects this on refresh and doubles the user's shares while halving their average cost basis.

**90-day analysis chart:**
`fetchPriceAnalysis()` builds a 90-day close-price series using the same compounding logic, scaled so the final point matches today's compounded price. Cached to `UserDefaults` once per calendar day.

---

## 5. Core Trading Mechanics

### Buying
- Sheet shows stepper (−, count, +, Max), cost summary, and remaining cash preview.
- Average cost basis is **weighted** across existing and new shares.
- Achievement counters and challenge trackers update immediately on buy.

### Selling
- Swipe left → `SellSheet` with share count stepper.
- Tracks whether the sale was at a **profit or loss** (for achievements).
- Removes position entirely when remaining shares drop to zero.

### Quick Buy (Portfolio tab)
An automated buy tool with three modes:
- **Passive** — scores stocks by `slopeRate × 3 - |changePercent|` (steady growers, low volatility)
- **Momentum** — scores by `changePercent × 0.5 + slopeRate × 0.5 + trendBonus`
- **Value** — scores by proximity to the stock's historical floor (`-(price - floor) / price`)

The algorithm buys up to 3 shares of each qualifying candidate (best score first), then dumps any leftover budget into the top pick.

### Sell All
Confirmation alert → sells all positions at current market prices.

---

## 6. User Interface

### Navigation
`MainDashboardView` is a **custom swipe-pager** (not TabView) with three pages:
- `HomeView` (tab 0)
- `MarketView` (tab 1)
- `PortfolioView` (tab 2)

A pure-SwiftUI `DragGesture` handles page switching with a rubber-band effect at the edges and directional bias (vertical drags pass through to scroll views).

### Top Bar (persistent)
- Left: **Info** button → `InfoView` sheet
- Center: 🔥 streak count + 💎 gem count
- Right: 🏆 achievements button (with red dot badge when claims are ready) + profile avatar

### Home Tab
- Welcome greeting + cash balance
- **Daily Challenge card** — progress bar, claim button
- **Mini net-worth card** — SwiftUI Charts area+line chart (CatmullRom interpolation), tappable → Portfolio tab
- Market highlights: Top Gainer, Top Loser, Steadiest (tappable → `StockAnalysisView`)

### Market Tab
- Stocks grouped by **collapsible sector sections** with SF Symbol icons
- Each stock row: `SwipeRevealCard` → swipe right to open `BuySheet`, tap to navigate to `StockAnalysisView`
- Pull-to-refresh triggers `refreshMarket()`

### Portfolio Tab
- Owned stocks list: swipe left → `SellSheet`
- Sell All button
- **Portfolio Insight Card** (AI-style analysis summary)
- **Quick Buy card**
- **Portfolio History chart** (net worth over time)

### Overlays
- **Gem burst animation** — pill pops in at center, floats up when gems are earned
- **Streak popup** — full-screen orange/yellow gradient banner on streak advance (≥2 days)
- **Tutorial overlay** — step-by-step guide shown on first login

### Stock Analysis View (`StockAnalysisView`)
Deep-dive view per stock: 90-day price chart, trend indicators, maxima/minima, floor support, sector info.

### Color System (`AppColors`)
Named semantic tokens: `background`, `surface`, `surfaceSecondary`, `accent`, `gain` (green), `loss` (red), `highlight` (purple/gold), `textPrimary/Secondary/Tertiary`, `cardBorder`, `divider`, `inputBackground`, `sheetBackground`, `warning`.

---

## 7. Gamification Systems

### Gems 💎
The in-app currency. Earned by:
- Daily challenge completion: **+5 gems**
- Login streak (≥2 days): **+1 gem/day**
- Achievement tier claims: **+10/30/60/100/200 gems** (Amateur → Platinum)

Spent on avatar unlocks (via the avatar picker).

### Daily Challenges
One challenge per calendar day, deterministically selected by `(year × 400 + month × 31 + day) % 10`. There are 10 challenge types:

| # | Challenge |
|---|---|
| 0 | Sell a rising stock |
| 1 | Buy 5 tech sector shares |
| 2 | Use Quick Buy ≥ $1,000 budget |
| 3 | Open advanced analysis for 3 different stocks |
| 4 | Bring cash up to $4,000 |
| 5 | Spend $2,000 on stocks today |
| 6 | Buy from Gaming or Shopping sector |
| 7 | Bring cash down to $6,000 |
| 8 | Grow net worth by 2% today |
| 9 | Use Quick Buy 3 times |

Dollar amounts scale proportionally to the user's chosen starting balance.

### Achievements
12 achievement categories, each with 5 tiers (Amateur → Bronze → Silver → Gold → Platinum). Tiers must be claimed sequentially:

| Achievement | What it tracks |
|---|---|
| Diverse Portfolio | Unique tickers ever owned |
| Investor | Max shares held in one stock at once |
| Gambler | Shares bought in ±2% volatile stocks |
| Intellectual | Advanced analysis screen opens |
| Spontaneous | Quick Buy uses |
| Safe Investor | Shares bought in steady (low-volatility) stocks |
| Momentum Buyer | Shares bought in fast-rising (+2%) stocks |
| Bargainer | Shares bought near a stock's floor price |
| Profit Taker | Profitable sells |
| Loss Cutter | Selling at a loss |
| Market Addict | App opens within rolling time windows (5/7/15/25/100 days) |
| Loyalty | Shares held continuously for extended periods (5/15/30/100/250 days) |

### Login Streaks
`advanceStreakIfNewDay()` checks if the last login was yesterday. Streaks reset to 1 on a gap day. Longest streak is tracked separately. Timestamps are pruned to a 100-day rolling window (for Market Addict).

---

## 8. Settings & Personalization

Accessed from the profile avatar button in the top bar.

- **Appearance:** Light / Dark / System (persisted; applies `preferredColorScheme` app-wide)
- **Sounds toggle:** Disables both `HapticsManager` and `SoundManager`
- **Block Cellular Data:** Restricts `StockService` to Wi-Fi only
- **Account Recovery:** Link a keycode (treated like email) for password recovery
- **Avatar Picker:** Buy avatars with gems across tiered categories
- **Reset Portfolio:** Choose starting balance ($500 / $10,000 / $100,000 / $100,000,000) — wipes all trades, gems, achievements (streak preserved)
- **Log Out / Delete Account**

---

## 9. Services Layer

| Service | Role |
|---|---|
| `AccountService` (actor) | All Supabase REST calls — login, create, fetch, save, delete, password recovery |
| `MarketService` | Writes/reads shared market price rows in Supabase (`market_prices` table) |
| `StockService` | Generates synthetic stock prices; builds 90-day analysis histories |
| `PriceAnalyzer` | Runs technical analysis on a close-price series (trend, support/resistance, etc.) |
| `HapticsManager` | Centralized haptic feedback (click, buy, sell, celebrate) |
| `SoundManager` | Plays ka-ching and celebration audio |
| `LoginRateLimiter` | Prevents brute-force login attempts |

---

## 10. Personal Reflections

> *Fill in this section with your own thoughts. Some prompts to get you started:*

### Most Challenging Part
<!-- What was the hardest thing to build? What made it difficult? -->

### Most Surprising Thing You Learned
<!-- Did anything surprise you while building this — about Swift, finance, or yourself? -->

### What You'd Do Differently
<!-- If you were starting over, what architectural or design choice would you change? -->

### Favorite Feature
<!-- Which feature are you most proud of? Why? -->

### What the App Taught You About Finance
<!-- Did building a stock simulator change how you think about the real stock market? -->

### What's Next
<!-- If you kept building this, what would you add or improve? -->

---

*Last updated: July 2026*
