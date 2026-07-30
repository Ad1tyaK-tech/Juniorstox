# stox junior — Technical README

A kid-friendly iOS stock analysis app built with SwiftUI. This document explains the math and logic powering every number you see in the app.

---

## Table of Contents

1. [Data Pipeline](#1-data-pipeline)
2. [Simple Moving Average (SMA)](#2-simple-moving-average-sma)
3. [Ordinary Least-Squares Linear Regression](#3-ordinary-least-squares-linear-regression)
4. [Annualized Volatility](#4-annualized-volatility)
5. [Local Extrema Detection](#5-local-extrema-detection)
6. [Trend Signal Logic](#6-trend-signal-logic)
7. [Price vs SMA Spread](#7-price-vs-sma-spread)
8. [Synthetic Price Generation](#8-synthetic-price-generation)
9. [Interactive Graph & Rolling SMA](#9-interactive-graph--rolling-sma)
10. [Architecture Overview](#10-architecture-overview)

---

## 1. Data Pipeline

**[TODO: describe the two paths — real API fetch vs. synthetic fallback]**

- **Real data**: `StockService` fetches 90 trading days of closing prices from a market data API using Swift's `async/await`. On success, `PriceAnalyzer.analyze(closePrices:)` runs on the real array.
- **Synthetic fallback**: If the network call fails (no API key, offline, rate-limited), the app falls back to `PriceAnalyzer.syntheticPrices(...)` which constructs a plausible 90-day series from just the current quote (price, change%, day high, day low). This means the chart always has something meaningful to show.

The separation of networking (`StockService`) from math (`PriceAnalyzer`) is intentional — it means every formula below can be tested independently with no network required.

---

## 2. Simple Moving Average (SMA)

### What it is

A Simple Moving Average smooths out daily noise by replacing each day's price with the average of the surrounding window of days. The app uses a **20-day SMA**, which approximates one trading month.

### Formula

$$SMA_{20}(t) = \frac{1}{\min(20,\, t+1)} \sum_{i=\max(0,\, t-19)}^{t} P_i$$

Where:
- $P_i$ = closing price on day $i$
- $t$ = current day index (0-based)
- The window shrinks to $t+1$ at the start of the series (fewer than 20 days available)

### Two uses in the app

| Use | Description |
|-----|-------------|
| **Single-value SMA** | Computed over the last 20 closes. Used in Trend Signal logic and the "Quantitative Stats" card. |
| **Rolling SMA line** | Computed at every day across the full 90-day history. Shown as the dashed white line on the interactive chart. |

### Why 20 days?

20 is the standard "short-term" SMA in technical analysis because there are roughly 20 trading days in a calendar month. It's sensitive enough to react to genuine trend shifts, but not so sensitive that it mirrors daily noise.

### What it tells you

- **Price above SMA**: recent momentum is pushing the stock above its "normal" baseline — often read as short-term strength.
- **Price below SMA**: the stock is lagging its own recent average — often read as short-term weakness.
- **Golden cross / death cross**: when a short-term SMA crosses above/below a longer-term SMA — classic buy/sell signals used by professional traders.

---

## 3. Ordinary Least-Squares Linear Regression

### What it is

OLS draws the **single best-fit straight line** through all 90 data points (day index vs. closing price). Its slope tells you the average price change per trading day over the full window.

### Why not just compare first and last price?

Using only two points is extremely sensitive to outliers. If the first or last day happened to be an anomalous spike, the slope would be meaningless. OLS uses every data point, so outliers have much less influence.

### Formula

Given pairs $(x_i, P_i)$ where $x_i = i$ (day index) and $P_i$ = closing price:

$$\text{slope} = \frac{n \sum x_i P_i - \sum x_i \sum P_i}{n \sum x_i^2 - \left(\sum x_i\right)^2}$$

Where $n$ = number of trading days (up to 90).

This is the standard closed-form solution for a two-variable linear regression: it minimizes the sum of squared vertical distances between each data point and the line.

### Implementation note

The denominator $n \sum x_i^2 - (\sum x_i)^2$ can equal zero if all x-values are identical (impossible here since $x_i = i$), but the code guards against it to avoid division-by-zero.

### Interpreting the slope

| Slope value | Meaning |
|-------------|---------|
| `+0.50` | Stock drifts ~$0.50 higher each trading session on average |
| `-0.20` | Stock loses ~$0.20 per session on average |
| `~0.00` | Essentially flat over the window |

**Important caveat**: OLS slope describes the past window only. It is not a prediction.

---

## 4. Annualized Volatility

### What it is

Volatility measures how wildly a stock's price swings. A low-volatility stock moves in a narrow band; a high-volatility stock can gain or lose 5–10% in a single day.

The app computes **annualized volatility** so it's directly comparable across different stocks and matches the industry-standard metric used in options pricing.

### Step 1 — Daily returns

$$r_i = \frac{P_i - P_{i-1}}{P_{i-1}}, \quad i = 1, 2, \ldots, n-1$$

This gives the percentage gain or loss on each day, expressed as a decimal (e.g., +2% → 0.02).

### Step 2 — Sample standard deviation

$$\sigma_{daily} = \sqrt{\frac{\sum_{i=1}^{n-1}(r_i - \bar{r})^2}{n-2}}$$

Where $\bar{r}$ is the mean daily return and we divide by $n-2$ (sample variance with one degree of freedom consumed by computing the mean, and starting from $i=1$).

**[TODO: verify whether the code uses n-1 or n-2 in the denominator and update accordingly]**

### Step 3 — Annualize

$$\sigma_{annual} = \sigma_{daily} \times \sqrt{252}$$

The factor $\sqrt{252}$ comes from there being approximately **252 trading days** in a US calendar year (52 weeks × 5 days, minus ~10 market holidays). Because variance scales linearly with time, standard deviation scales with the square root of time.

### Interpreting volatility

| Range | Label | What it means |
|-------|-------|---------------|
| < 15% | Low | Stable, slow-moving stock (utilities, consumer staples) |
| 15–30% | Moderate | Typical large-cap tech or finance stock |
| 30–50% | High | Growth stock or mid-cap with frequent news |
| > 50% | Very High | Speculative or small-cap; large swings likely |

Volatility is the core input to options pricing models like Black-Scholes and is directly related to the "risk" component of most portfolio theories.

---

## 5. Local Extrema Detection

### What it is

The app scans the 90-day price series for **local peaks** (resistance levels) and **local troughs** (support levels) — days where the price reversed direction relative to both its neighbors.

### Algorithm

For each interior day $i$ (i.e., $1 \le i \le n-2$):

- **Local maximum (peak)**: $P_i > P_{i-1}$ AND $P_i > P_{i+1}$
- **Local minimum (trough)**: $P_i < P_{i-1}$ AND $P_i < P_{i+1}$

Edge days (index 0 and $n-1$) are excluded because they only have one neighbor.

### Why strictly greater/less than?

Using strict inequality means a plateau (e.g., three identical prices in a row) is not counted as an extremum. This avoids noise from flat periods.

### Interpreting extrema

- **Peaks (resistance)**: price levels where selling pressure historically dominated — the stock struggled to push past them before falling back. If price approaches a past peak, traders watch closely.
- **Troughs (support)**: price levels where buying interest historically stepped in. A stock bouncing off the same trough multiple times is seen as having strong support at that level.
- **Swing range**: the difference between the highest peak and lowest trough over 90 days measures how wide the stock's trading range has been.

---

## 6. Trend Signal Logic

### What it is

The app combines two independent indicators into a single traffic-light signal: **Bullish**, **Neutral**, or **Bearish**.

### Logic table

| Price vs SMA | OLS Slope | Signal |
|-------------|-----------|--------|
| Price > SMA | Slope > 0 | **Bullish** — both structure and momentum point up |
| Price < SMA | Slope < 0 | **Bearish** — both structure and momentum point down |
| Any other combination | — | **Neutral** — signals conflict |

### Why require both conditions?

Using either indicator alone produces more false signals:
- A positive slope during a brief rally can still be below the SMA (short-term bounce in a downtrend).
- A price above SMA can have a negative slope if the stock is starting to roll over.

Requiring agreement between the two filters out noise. This two-factor confirmation approach is analogous to how professional systems avoid acting on a single uncorroborated signal.

---

## 7. Price vs SMA Spread

### Formula

$$\text{spread\%} = \frac{P_{current} - SMA_{20}}{SMA_{20}} \times 100$$

### Interpretation

This number shows how far (in percentage terms) the current price sits above or below its 20-day average.

- **Large positive spread** (e.g., +8%): the stock has moved significantly above its recent average — potentially **overbought**, meaning it may be due for a pullback.
- **Large negative spread** (e.g., -8%): price is far below its recent average — potentially **oversold**, meaning it may be due for a bounce.
- **Near zero**: price is hugging its average, no strong directional signal.

"Overbought/oversold" does not mean a reversal is guaranteed — a strong trend can stay overbought for weeks. It's a relative measure, not a prediction.

---

## 8. Synthetic Price Generation

When real historical data is unavailable (network error, no API key, rate limit), the app generates a plausible 90-day series deterministically from the live quote alone. This is a fallback for display purposes, not real data.

### Inputs

| Input | Source |
|-------|--------|
| `currentPrice` | Live quote |
| `changePercent` | Today's % change vs. prior close |
| `dayHigh`, `dayLow` | Today's intraday range |
| `ticker` | Stock symbol string |

### Step 1 — Estimate daily volatility

$$\sigma_{daily} = \max\!\left(0.006,\ \frac{dayHigh - dayLow}{currentPrice} \times 0.5\right)$$

This is a simplified version of the **Parkinson volatility estimator**, which uses the intraday high-low range as a proxy for daily volatility. The floor of 0.6% prevents unrealistically flat series.

### Step 2 — Deterministic random noise (LCG)

To make the chart look different per stock but stable across app refreshes (so the graph doesn't jump around every time prices update), the app uses a **Linear Congruential Generator (LCG)** seeded from the ticker string:

$$\text{seed} = \sum_{\text{char} \in \text{ticker}} \text{unicode}(\text{char}) \cdot 31^k$$

$$\text{state}_{n+1} = \text{state}_n \times 6{,}364{,}136{,}223{,}846{,}793{,}005 + 1{,}442{,}695{,}040{,}888{,}963{,}407 \pmod{2^{64}}$$

The constants are the standard Knuth LCG multiplier and increment for 64-bit arithmetic. Dividing the output by $2^{31}$ and re-centering gives a uniform $[-1, 1]$ noise value per day.

An LCG is not cryptographically secure, but that's irrelevant here — the goal is determinism and visual variety, not unpredictability.

### Step 3 — Build the series

$$P_0 = \frac{currentPrice}{1 + totalReturn}, \quad P_i = P_{i-1} \times (1 + dailyDrift + noise_i \times \sigma_{daily})$$

Where $totalReturn = changePercent / 100$ and $dailyDrift = totalReturn / 90$.

### Step 4 — Anchor to current price

$$P_i' = P_i \times \frac{currentPrice}{P_{89}}$$

Rescaling every price proportionally ensures the series ends exactly at `currentPrice`, regardless of accumulated noise.

---

## 9. Interactive Graph & Rolling SMA

### Chart marks

| Mark | Visual | Data |
|------|--------|------|
| `AreaMark` | Gradient fill | Price, colored by trend signal |
| `LineMark` (Price) | Solid line | `closePrices[i]` |
| `LineMark` (SMA-20) | Dashed white line | `smaLine[i]` — rolling 20-day SMA |
| `RuleMark` | Vertical dashed cursor | Active only while dragging |
| `PointMark` × 2 | Dots on both lines | Active only while dragging |

### Rolling SMA line

Unlike the single SMA value shown in the stats card (which is only the last window), the chart shows the SMA **evolving across the full 90 days**. This lets you see visually where the price crossed above or below its moving average in the past.

### Drag-to-inspect cursor

Built with Swift Charts' `chartOverlay` API and a `DragGesture`:

1. The overlay's `ChartProxy` converts the finger's x-position (in screen points) into a day index using `proxy.value(atX:)`.
2. The selected day index drives a `RuleMark` (vertical cursor line) and two `PointMark` instances (one on the price line, one on the SMA line).
3. A tooltip follows the cursor horizontally (clamped to stay inside the plot area) showing the closing price and SMA value for that exact day.

This is analogous to the pointer on a Desmos graph — dragging across the surface snaps to data and displays values at each point.

---

## 10. Architecture Overview

```
StockService          — async/await networking, fetches real historical closes
PriceAnalyzer         — pure static math engine, zero side effects, zero network
  analyze()           — SMA, OLS slope, volatility, local extrema, trend signal
  syntheticPrices()   — deterministic fake series from a single live quote
PriceAnalysis         — plain value type (struct) holding all computed results
GraphView             — SwiftUI Charts rendering + drag gesture interaction
StockAnalysisView     — assembles chart + stats cards + glossary
```

**Design principle**: `PriceAnalyzer` is intentionally pure — given the same `[Double]` array it always returns the same result. This makes it trivial to unit test every formula without mocking a network layer.

---

*Written for stox junior — a portfolio project demonstrating applied quantitative finance in Swift.*
