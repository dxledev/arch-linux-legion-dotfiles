.pragma library

function positiveId(value) {
    if (typeof value === "number")
        return Number.isSafeInteger(value) && value > 0 ? value : null;

    if (typeof value !== "string" || !/^[1-9]\d*$/.test(value))
        return null;

    const id = Number(value);
    return Number.isSafeInteger(id) ? id : null;
}

function configuredCount(value) {
    const count = positiveId(value);
    return Math.max(5, count ?? 0);
}

function fallbackStart(value) {
    return positiveId(value) ?? 1;
}

function monitorAvailable(monitor) {
    return !!monitor && typeof monitor === "object"
        && (monitor.id !== undefined && monitor.id !== null || monitor.name || monitor.description);
}

function monitorIdentityMatches(value, monitor) {
    if (typeof value !== "string" && typeof value !== "number")
        return false;

    const identity = String(value);
    if (/^\d+$/.test(identity) && monitor.id !== undefined)
        return identity === String(monitor.id);

    if (identity.startsWith("desc:")) {
        const descriptionPrefix = identity.slice(5);
        return descriptionPrefix.length > 0 && monitor.description?.startsWith(descriptionPrefix);
    }

    return identity === monitor.name;
}

function workspaceOnMonitor(workspace, monitor) {
    return monitorIdentityMatches(workspace?.monitor, monitor);
}

function ruleMonitor(rule) {
    const value = rule?.monitor;
    if (typeof value !== "string" && typeof value !== "number")
        return null;

    const identity = String(value);
    return identity.length > 0 ? identity : null;
}

function validRules(rules) {
    const normalized = [];
    for (const rule of Array.isArray(rules) ? rules : []) {
        if (rule?.enabled === false)
            continue;

        const id = positiveId(rule.workspaceString);
        const monitor = ruleMonitor(rule);
        if (id === null || monitor === null)
            continue;

        normalized.push({
            id,
            monitor,
            persistent: typeof rule.persistent === "boolean" ? rule.persistent : null
        });
    }
    return normalized;
}

function ruleIndex(rules) {
    const index = new Map();
    for (const rule of validRules(rules))
        index.set(rule.id, rule);
    return index;
}

function persistentRuleIds(rules, monitor) {
    const ids = new Set();
    for (const rule of rules) {
        if (rule.persistent === true && (!monitor || monitorIdentityMatches(rule.monitor, monitor)))
            ids.add(rule.id);
    }
    return ids;
}

function livePersistentIds(workspaces, monitor, rulesById) {
    const ids = new Set();
    for (const workspace of Array.isArray(workspaces) ? workspaces : []) {
        const id = positiveId(workspace?.id);
        if (id === null || workspace.ispersistent !== true)
            continue;
        const rule = rulesById.get(id);
        if (rule?.persistent === false)
            continue;
        if (monitor) {
            const assignedHere = rule
                ? monitorIdentityMatches(rule.monitor, monitor)
                : workspaceOnMonitor(workspace, monitor);
            if (!assignedHere)
                continue;
        }
        ids.add(id);
    }
    return ids;
}

function persistentIds(monitor, workspaces, rules, perMonitor) {
    const rulesById = ruleIndex(rules);
    const ids = persistentRuleIds(rulesById.values(), perMonitor ? monitor : null);
    for (const id of livePersistentIds(workspaces, perMonitor ? monitor : null, rulesById))
        ids.add(id);
    return ids;
}

function foreignRuleIds(rules, monitor) {
    const ids = new Set();
    for (const [id, rule] of rules) {
        if (!monitorIdentityMatches(rule.monitor, monitor))
            ids.add(id);
    }
    return ids;
}

function foreignLiveIds(workspaces, monitor) {
    const ids = new Set();
    for (const workspace of Array.isArray(workspaces) ? workspaces : []) {
        const id = positiveId(workspace?.id);
        if (id !== null && !workspaceOnMonitor(workspace, monitor))
            ids.add(id);
    }
    return ids;
}

function activeId(monitor) {
    return positiveId(monitor?.activeWorkspace?.id);
}

function addEligibleLiveIds(ids, workspaces, monitor, active, excluded) {
    for (const workspace of Array.isArray(workspaces) ? workspaces : []) {
        const id = positiveId(workspace?.id);
        if (id === null || !workspaceOnMonitor(workspace, monitor) || excluded.has(id))
            continue;
        if (Number(workspace.windows) > 0 || id === active)
            ids.add(id);
    }
}

function fillFallbackIds(ids, count, first, excluded) {
    let candidate = fallbackStart(first);
    while (ids.size < count) {
        if (!excluded.has(candidate))
            ids.add(candidate);
        candidate += 1;
    }
}

function monitorFallbackIds(monitor, workspaces, rules, count, first) {
    const rulesById = ruleIndex(rules);
    const excluded = foreignRuleIds(rulesById, monitor);
    for (const id of foreignLiveIds(workspaces, monitor))
        excluded.add(id);

    const ids = new Set();
    const active = activeId(monitor);
    if (active !== null && !excluded.has(active))
        ids.add(active);
    addEligibleLiveIds(ids, workspaces, monitor, active, excluded);
    fillFallbackIds(ids, configuredCount(count), first, excluded);
    return [...ids].sort((a, b) => a - b);
}

function globalFallbackIds(monitor, workspaces, count, first) {
    const ids = new Set();
    const active = activeId(monitor);
    if (active !== null)
        ids.add(active);

    for (const workspace of Array.isArray(workspaces) ? workspaces : []) {
        const id = positiveId(workspace?.id);
        if (id !== null && Number(workspace.windows) > 0)
            ids.add(id);
    }

    fillFallbackIds(ids, configuredCount(count), first, new Set());
    return [...ids].sort((a, b) => a - b);
}

function visibleIds(monitor, workspaces, rules, count, first, perMonitor) {
    if (perMonitor && !monitorAvailable(monitor))
        return [];

    const persistent = persistentIds(monitor, workspaces, rules, perMonitor);
    if (persistent.size > 0)
        return [...persistent].sort((a, b) => a - b);

    if (!perMonitor)
        return globalFallbackIds(monitor, workspaces, count, first);

    return monitorFallbackIds(monitor, workspaces, rules, count, first);
}
