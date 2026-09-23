.pragma library

const MAX_TEXT_LENGTH = 400;

function isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
}

function safeText(value) {
    if (typeof value !== "string" && typeof value !== "number" && typeof value !== "boolean")
        return "";

    return String(value)
        .replace(/\u001b\[[0-?]*[ -/]*[@-~]/g, "")
        .replace(/[\u0000-\u001f\u007f-\u009f\u202a-\u202e\u2066-\u2069]/g, " ")
        .replace(/\s+/g, " ")
        .trim()
        .slice(0, MAX_TEXT_LENGTH);
}

function numberOrNull(value) {
    if (value === null || value === undefined || value === "")
        return null;

    const number = Number(value);
    return Number.isFinite(number) ? number : null;
}

function timestampMilliseconds(value) {
    if (typeof value === "number" && Number.isFinite(value))
        return value < 1000000000000 ? value * 1000 : value;
    if (typeof value !== "string")
        return null;

    const parsed = Date.parse(value);
    return Number.isFinite(parsed) ? parsed : null;
}

function normalizeMetric(metric) {
    const percentValue = numberOrNull(metric.percent);
    const windowSeconds = numberOrNull(metric.window_secs);
    const resetAtMs = timestampMilliseconds(metric.reset_at);
    let elapsedPercent = null;

    if (windowSeconds > 0 && resetAtMs !== null) {
        const remainingSeconds = Math.max(0, (resetAtMs - Date.now()) / 1000);
        elapsedPercent = Math.max(0, Math.min(100, 100 * (windowSeconds - remainingSeconds) / windowSeconds));
    }

    return {
        label: safeText(metric.label),
        percent: percentValue === null ? null : Math.max(0, Math.min(100, percentValue)),
        value: safeText(metric.value),
        detail: safeText(metric.detail),
        severity: safeText(metric.severity).toLowerCase(),
        resetAtMs: resetAtMs,
        windowSeconds: windowSeconds,
        elapsedPercent: elapsedPercent
    };
}

function normalizeSection(section, metrics, metricPosition) {
    const type = safeText(section.type).toLowerCase();

    if (type === "spacer")
        return { type: "spacer" };

    if (type === "metric") {
        const metric = normalizeMetric(section);
        const sourceMetric = metrics[metricPosition.value];
        metricPosition.value++;

        if (sourceMetric) {
            metric.windowSeconds = sourceMetric.windowSeconds;
            metric.elapsedPercent = sourceMetric.elapsedPercent;
            if (metric.resetAtMs === null)
                metric.resetAtMs = sourceMetric.resetAtMs;
        }

        return { type: "metric", metric: metric };
    }

    if (type === "block") {
        const body = Array.isArray(section.body) ? section.body : typeof section.body === "string" ? section.body.split(/\r?\n/) : [];
        return {
            type: "block",
            label: safeText(section.label),
            body: body.map(safeText).filter(line => line.length > 0)
        };
    }

    return {
        type: "text",
        label: safeText(section.label),
        value: safeText(section.value)
    };
}

function normalizeEntry(entry, index) {
    const id = safeText(entry.id) || safeText(entry.name) || `provider-${index + 1}`;
    const error = safeText(entry.error);
    const failed = error.length > 0 || safeText(entry.status).toLowerCase() === "error";
    const metrics = failed ? [] : (Array.isArray(entry.metrics) ? entry.metrics : [])
        .filter(isObject)
        .map(normalizeMetric);
    const metricPosition = { value: 0 };
    let sections = failed ? [] : (Array.isArray(entry.sections) ? entry.sections : [])
        .filter(isObject)
        .map(section => normalizeSection(section, metrics, metricPosition));

    if (!failed && sections.length === 0 && metrics.length > 0)
        sections = metrics.map(metric => ({ type: "metric", metric: metric }));

    return {
        id: id,
        name: safeText(entry.name) || id,
        displayName: safeText(entry.display_name) || safeText(entry.name) || id,
        shortName: safeText(entry.short_name),
        brand: safeText(entry.brand),
        plan: safeText(entry.plan),
        error: error || (failed ? "Provider reported an error." : ""),
        failed: failed,
        stale: entry.stale === true,
        fetchedAtMs: timestampMilliseconds(entry.fetched_at),
        credits: safeText(entry.reset_credits),
        metrics: metrics,
        sections: sections
    };
}

function parseReport(output) {
    if (typeof output !== "string" || output.trim().length === 0)
        return { ok: false, message: "AI Usage returned no report." };

    let payload;
    try {
        payload = JSON.parse(output);
    } catch (error) {
        return { ok: false, message: "AI Usage returned invalid JSON." };
    }

    if (!isObject(payload) || !Array.isArray(payload.entries))
        return { ok: false, message: "AI Usage returned an invalid report." };

    return {
        ok: true,
        report: {
            primary: safeText(payload.primary),
            entries: payload.entries.filter(isObject).map(normalizeEntry)
        }
    };
}

function parseProcessResult(exitCode, output, timedOut) {
    if (timedOut === true || exitCode === 124 || exitCode === 137)
        return { ok: false, message: "AI Usage refresh timed out." };

    const result = parseReport(output);
    if (result.ok)
        return result;
    if (exitCode !== 0)
        return { ok: false, message: "AI Usage could not refresh the report." };

    return result;
}

function availableEntries(entries) {
    return (Array.isArray(entries) ? entries : []).filter(entry => isObject(entry) && !entry.failed);
}

function applyResult(currentEntries, hasReport, result) {
    if (!result.ok) {
        return {
            entries: currentEntries,
            hasReport: hasReport,
            stale: true,
            refreshError: result.message
        };
    }

    return {
        entries: result.report.entries,
        hasReport: true,
        stale: false,
        refreshError: ""
    };
}
