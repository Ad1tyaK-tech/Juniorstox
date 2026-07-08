// refresh-price-history.js
// Runs in GitHub Actions once per day (weekdays, after US market close).
// Fetches 90-day closing prices from Alpha Vantage and upserts them into
// the Supabase price_history table. Every user's device reads from that table,
// so the Alpha Vantage key is never shipped in the app and the 25 req/day
// free-tier limit is consumed server-side in one controlled burst.

import { createClient } from '@supabase/supabase-js'

// Must match the realTicker values in StockModel.swift → stockAliases.
const TICKERS = [
    'AAPL',  // Pear
    'MSFT',  // Macrodense
    'GOOG',  // Geggol
    'META',  // Atem Systems
    'NVDA',  // Nmovia
    'AMD',   // Strong Mini Devices
    'AMZN',  // Bravozon
    'TSLA',  // Einstein
    'COIN',  // Dollarstand
    'RBLX',  // Playbit
]

// Alpha Vantage free tier: 25 req/day and 5 req/min.
// 13 s between calls → ~4.6 req/min, safely under both limits.
// 10 tickers × 1 call = 10 calls total per run.
const DELAY_MS = 13_000

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
}

async function fetchCloses(ticker, apiKey) {
    const url = `https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=${ticker}&outputsize=compact&apikey=${apiKey}`
    const res = await fetch(url)

    if (!res.ok) {
        throw new Error(`HTTP ${res.status} for ${ticker}`)
    }

    const json = await res.json()
    const series = json['Time Series (Daily)']

    if (!series) {
        // AV returns a "Note" or "Information" key when rate-limited or key is invalid.
        const note = json['Note'] ?? json['Information'] ?? JSON.stringify(json)
        throw new Error(`No time series for ${ticker}: ${note}`)
    }

    // Sort by date string (ISO format sorts lexicographically = chronologically).
    const closes = Object.entries(series)
        .sort(([a], [b]) => a.localeCompare(b))
        .slice(-90)
        .map(([, bar]) => parseFloat(bar['4. close']))

    if (closes.length === 0) {
        throw new Error(`Empty close series for ${ticker}`)
    }

    return closes
}

async function main() {
    const avKey           = process.env.ALPHA_VANTAGE_API_KEY
    const supabaseUrl     = process.env.SUPABASE_URL
    const supabaseRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY

    if (!avKey || !supabaseUrl || !supabaseRoleKey) {
        console.error('Missing required environment variables.')
        console.error('Required: ALPHA_VANTAGE_API_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY')
        process.exit(1)
    }

    const supabase = createClient(supabaseUrl, supabaseRoleKey)
    const dateString = new Date().toISOString().slice(0, 10) // "yyyy-MM-dd"

    const updates = []
    const failed  = []

    console.log(`Fetching 90-day history for ${TICKERS.length} tickers (${dateString})...`)

    for (let i = 0; i < TICKERS.length; i++) {
        const ticker = TICKERS[i]
        try {
            const closes = await fetchCloses(ticker, avKey)
            updates.push({
                ticker,
                close_prices: closes,
                date_string:  dateString,
                updated_at:   new Date().toISOString(),
            })
            console.log(`  ✓ ${ticker.padEnd(5)} ${closes.length} closes  (latest $${closes.at(-1).toFixed(2)})`)
        } catch (err) {
            console.error(`  ✗ ${ticker}: ${err.message}`)
            failed.push(ticker)
        }

        // Skip the delay after the last ticker.
        if (i < TICKERS.length - 1) {
            await sleep(DELAY_MS)
        }
    }

    if (updates.length === 0) {
        console.error('No data fetched — aborting upsert.')
        process.exit(1)
    }

    const { error } = await supabase
        .from('price_history')
        .upsert(updates, { onConflict: 'ticker' })

    if (error) {
        console.error('Supabase upsert failed:', error.message)
        process.exit(1)
    }

    console.log(`\n✅ Upserted ${updates.length} rows to price_history.`)
    if (failed.length > 0) {
        console.warn(`⚠️  Skipped (fetch error): ${failed.join(', ')}`)
    }
}

main().catch(err => {
    console.error('Fatal error:', err.message)
    process.exit(1)
})
