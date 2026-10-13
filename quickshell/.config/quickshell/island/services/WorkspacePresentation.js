.pragma library

function isAxis(value) {
    return value === "horizontal" || value === "vertical"
}

function normalizeLayout(value) {
    var normalized = String(value || "").trim().toLowerCase()
    if (normalized === "scrollingfix") return "scrolling"
    if (["grid", "spiral", "manual", "centerstack"].indexOf(normalized) !== -1)
        return "lua:" + normalized
    return normalized
}

function isScrollingLayout(value) {
    var normalized = String(value || "").trim().toLowerCase()
    return normalized === "scrolling" || normalized === "scrollingfix"
}

function isSupportedLayout(value, layouts) {
    return (Array.isArray(layouts) ? layouts : []).indexOf(normalizeLayout(value)) !== -1
}

function canOpenAxis(statusKnown, layout, reportedLocked, effectiveAxis) {
    return statusKnown && reportedLocked !== true && !isScrollingLayout(layout) && isAxis(effectiveAxis)
}

function availableMenuEntries(entries, visibilityValidated, axisAvailable) {
    var source = Array.isArray(entries) ? entries : []
    if (visibilityValidated && axisAvailable) return source.slice()
    return source.filter(function(entry) { return entry.id !== "workspace-axis" })
}

function filterAvailableIds(ids, availableIds) {
    var available = Array.isArray(availableIds) ? availableIds : []
    return (Array.isArray(ids) ? ids : []).filter(function(id) { return available.indexOf(id) !== -1 })
}

function canStartAction(actionPending, writerRunning, operation, value, layouts) {
    if (actionPending || writerRunning) return false
    if (operation === "axis") return isAxis(value)
    if (operation === "layout") return isSupportedLayout(value, layouts)
    return false
}

function shouldStartAction(actionPending, pendingOperation, writerRunning) {
    return actionPending && !!pendingOperation && !writerRunning
}

function createOpenRequest(generation, mode, monitorName) {
    return {
        generation: generation,
        mode: mode,
        monitorName: String(monitorName || ""),
        pending: true
    }
}

function cancelOpenRequest(generation) {
    return {
        generation: generation,
        mode: -1,
        monitorName: "",
        pending: false
    }
}

function resolveOpenRequest(request, generation, currentMode, statusSucceeded, axisAvailable, actionPending) {
    var current = !!request && request.pending && request.generation === generation
        && request.mode === currentMode
    return {
        current: current,
        allowed: current && statusSucceeded === true && axisAvailable === true && actionPending !== true,
        monitorName: current ? request.monitorName : ""
    }
}
