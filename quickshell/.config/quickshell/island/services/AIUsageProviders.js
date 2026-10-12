.pragma library

const MAX_PROVIDER_IDS = 256;

function normalizedProviderIds(values) {
    if (!Array.isArray(values))
        return [];

    const ids = [];
    for (const value of values) {
        if (typeof value !== "string")
            continue;

        const id = value.trim();
        if (id.length === 0 || id.length > 160 || /[\u0000-\u001f\u007f-\u009f]/.test(id) || ids.includes(id))
            continue;

        ids.push(id);
        if (ids.length >= MAX_PROVIDER_IDS)
            break;
    }

    return ids;
}

function parseDiscoveryResult(exitCode, output, timedOut) {
    if (timedOut === true || exitCode === 124 || exitCode === 137)
        return { ok: false, message: "Configured AI providers could not be checked." };
    if (exitCode !== 0)
        return { ok: false, message: "Configured AI providers could not be checked." };

    let payload;
    try {
        payload = JSON.parse(output);
    } catch (error) {
        return { ok: false, message: "Configured AI providers returned invalid data." };
    }

    if (payload === null || typeof payload !== "object" || payload.ok !== true || !Array.isArray(payload.providerIds))
        return { ok: false, message: "Configured AI providers returned invalid data." };

    return { ok: true, providerIds: normalizedProviderIds(payload.providerIds) };
}

function availableEntries(entries, providerIds) {
    const allowed = new Set(normalizedProviderIds(providerIds));
    return (Array.isArray(entries) ? entries : []).filter(entry => {
        if (entry === null || typeof entry !== "object" || typeof entry.id !== "string")
            return false;

        return allowed.has(entry.id);
    });
}
