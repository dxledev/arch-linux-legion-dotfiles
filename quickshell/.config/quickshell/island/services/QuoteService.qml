pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "CalendarQuotes.js" as Quotes

// Motivational quotes for the Calendar header. A batch of 50 comes from ZenQuotes
// (https://zenquotes.io, free tier, no key) and is cached under the state directory; every open of
// the panel steps to the next quote, so it differs each time, including across shell restarts. A
// small bundled list covers offline use and the very first open. Fetch failures are silent.
Singleton {
    id: root

    readonly property string url: Quickshell.env("ISLAND_QUOTES_URL") || "https://zenquotes.io/api/quotes"
    readonly property int maxAgeMs: 12 * 60 * 60 * 1000
    readonly property int refetchBelow: 8

    readonly property int recentKeep: 30

    // Cached batch: { fetchedAt, index, last, recent: [quote text], quotes: [{ q, a }] }. ZenQuotes
    // may hand back the same batch twice, so `recent` keeps repeats out across refetches.
    property var cache: ({ fetchedAt: 0, index: 0, last: "", recent: [], quotes: [] })
    property bool fetching: fetcher.running

    // The next quote to show: { q, a }. Never the same as the previous one.
    function take() {
        const quotes = cache.quotes
        const pool = quotes.length > 0 ? quotes : Quotes.fallback
        const start = quotes.length > 0 ? cache.index % pool.length : Math.floor(Math.random() * pool.length)
        // First quote from `start` not shown recently (and never the last one); if everything was
        // shown recently, just move on to the next.
        let offset = 0
        while (offset < pool.length && (pool[(start + offset) % pool.length].q === cache.last
            || cache.recent.includes(pool[(start + offset) % pool.length].q))) offset++
        if (offset >= pool.length) offset = pool.length > 1 && pool[start].q === cache.last ? 1 : 0
        const index = (start + offset) % pool.length
        const picked = pool[index]
        if (quotes.length > 0) cache.index = index + 1
        cache.last = picked.q
        cache.recent = cache.recent.filter(text => text !== picked.q).concat(picked.q).slice(-recentKeep)
        save()
        if (stale()) refresh()
        return picked
    }

    function stale() {
        const remaining = cache.quotes.length - cache.index
        return cache.quotes.length === 0 || remaining < refetchBelow || Date.now() - cache.fetchedAt > maxAgeMs
    }

    function refresh() {
        if (!fetcher.running) fetcher.running = true
    }

    function restore(raw) {
        try {
            const data = JSON.parse(raw)
            root.cache = {
                fetchedAt: Number(data.fetchedAt) || 0,
                index: Math.max(0, Math.floor(Number(data.index) || 0)),
                last: typeof data.last === "string" ? data.last : "",
                recent: Array.isArray(data.recent) ? data.recent.filter(text => typeof text === "string").slice(-recentKeep) : [],
                quotes: (data.quotes || []).filter(entry => Quotes.clean(entry))
            }
        } catch (error) {
            // Missing or unreadable cache: start over with the bundled list; the next fetch rewrites it.
        }
    }

    function save() {
        store.setText(JSON.stringify(cache) + "\n")
    }

    FileView {
        id: store

        path: ThemeService.stateDirectory + "/calendar-quotes.json"
        blockLoading: true
        atomicWrites: true
        printErrors: false
        onLoaded: root.restore(text())
    }

    Component.onCompleted: restore(store.text())

    Process {
        id: fetcher

        command: ["curl", "-fsS", "-m", "10", "-A", "island-calendar", "--", root.url]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: code => {
            if (code !== 0) return
            let quotes = []
            try { quotes = Quotes.parse(stdout.text) } catch (error) { return }
            if (quotes.length < 5) return
            root.cache = { fetchedAt: Date.now(), index: 0, last: root.cache.last, recent: root.cache.recent, quotes: quotes }
            root.save()
        }
    }
}
