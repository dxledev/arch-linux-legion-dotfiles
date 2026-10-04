function matchScore(text, query, matching) {
    text = text.toLowerCase();
    if (text === query) return 1000;
    if (text.startsWith(query)) return 800 - text.length;
    const position = text.indexOf(query);
    if (position >= 0) return 600 - position - text.length;
    if (matching !== "Fuzzy") return -1;
    let cursor = 0;
    let gaps = 0;
    for (const character of query) {
        const next = text.indexOf(character, cursor);
        if (next < 0) return -1;
        gaps += next - cursor;
        cursor = next + 1;
    }
    return 300 - gaps - text.length;
}

function results(apps, query, settings, usage) {
    query = query.trim().toLowerCase();
    const matching = settings.launcherMatching || "Fuzzy";
    const order = (query ? settings.launcherSearchOrder : settings.launcherDefaultOrder) || (query ? "Relevance" : "App list order");
    return apps.map((app, index) => {
        const nameScore = matchScore(app.name, query, matching);
        const extraScore = settings.launcherSearchDescriptions
            ? matchScore(app.description + " " + app.keywords.join(" "), query, matching) - 150 : -1;
        return {app: app, index: index, score: Math.max(nameScore, extraScore)};
    }).filter(result => !query || result.score >= 0).sort((a, b) => {
        if (order === "Relevance" && a.score !== b.score) return b.score - a.score;
        if (order === "Most used") {
            const difference = (usage[b.app.id]?.count || 0) - (usage[a.app.id]?.count || 0);
            if (difference) return difference;
        }
        if (order === "Recently used") {
            const difference = (usage[b.app.id]?.lastUsed || 0) - (usage[a.app.id]?.lastUsed || 0);
            if (difference) return difference;
        }
        if (order === "App list order") return a.index - b.index;
        return a.app.name.localeCompare(b.app.name) || a.index - b.index;
    }).map(result => result.app);
}
