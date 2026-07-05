// refresh-stocks.js
// Runs in GitHub Actions every 2 hours.
// Fetches live quotes from Finnhub and upserts them into the Supabase
// stock_prices table. The mobile app reads from that table — the Finnhub
// API key never touches the device.

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

// Small delay between Finnhub calls — free tier allows 60 req/min.
// 300ms × 10 tickers = ~3 seconds total, well within the limit.
const DELAY_MS = 300

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
}

async function fetchQuote(ticker, apiKey) {
    const url = `https://finnhub.io/api/v1/quote?symbol=${ticker}&token=${apiKey}`
    const res = await fetch(url)

    if (!res.ok) {
        throw new Error(`HTTP ${res.status} for ${ticker}`)
    }

    const data = await res.json()

    // Finnhub returns c=0 when the market is closed or the symbol is invalid.
    // We still upsert it so the table row gets a fresh last_updated timestamp,
    // keeping the cache valid. A zero price will cause the app to fall back to Finnhub.
    return {
        ticker,
        price:          data.c  ?? 0,
        change_percent: data.dp ?? 0,
        last_updated:   new Date().toISOString(),
    }
}

async function main() {
    const finnhubKey      = process.env.FINNHUB_API_KEY
    const supabaseUrl     = process.env.SUPABASE_URL
    const supabaseRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY

    if (!finnhubKey || !supabaseUrl || !supabaseRoleKey) {
        console.error('Missing required environment variables.')
        console.error('Required: FINNHUB_API_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY')
        process.exit(1)
    }

    // Service role key bypasses RLS — used only here, never shipped in the app.
    const supabase = createClient(supabaseUrl, supabaseRoleKey)

    const updates = []
    const failed  = []

    console.log(`Fetching quotes for ${TICKERS.length} tickers...`)

    for (const ticker of TICKERS) {
        try {
            const row = await fetchQuote(ticker, finnhubKey)
            updates.push(row)
            console.log(`  ✓ ${ticker.padEnd(5)} $${row.price.toFixed(2)}  (${row.change_percent >= 0 ? '+' : ''}${row.change_percent.toFixed(2)}%)`)
        } catch (err) {
            console.error(`  ✗ ${ticker}: ${err.message}`)
            failed.push(ticker)
        }

        await sleep(DELAY_MS)
    }

    if (updates.length === 0) {
        console.error('No quotes fetched — aborting upsert.')
        process.exit(1)
    }

    const { error } = await supabase
        .from('stock_prices')
        .upsert(updates, { onConflict: 'ticker' })

    if (error) {
        console.error('Supabase upsert failed:', error.message)
        process.exit(1)
    }

    console.log(`\n✅ Upserted ${updates.length} rows to stock_prices.`)
    if (failed.length > 0) {
        console.warn(`⚠️  Skipped (fetch error): ${failed.join(', ')}`)
    }
}

main().catch(err => {
    console.error('Fatal error:', err.message)
    process.exit(1)
})
