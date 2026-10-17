.pragma library

// Arrow-key navigation over whatever a panel makes Tab-focusable. Panels with their own arrow handling
// never get here: this only sees keys nothing else accepted.

function reachable(item) {
    return item.visible && item.enabled && item.opacity > 0 && item.width > 0 && item.height > 0
}

// Every Tab-focusable item under root, in document order.
function collect(root, found = []) {
    for (const child of root.children) {
        if (!child.visible || child.opacity <= 0) continue
        if (child.activeFocusOnTab && reachable(child)) found.push(child)
        collect(child, found)
    }
    return found
}

// Whether item is an ancestor of other: a card and the button inside it count as one stop.
function contains(item, other) {
    for (let parent = other.parent; parent; parent = parent.parent) {
        if (parent === item) return true
    }
    return false
}

function inside(root, item) {
    for (let parent = item; parent; parent = parent.parent) {
        if (parent === root) return true
    }
    return false
}

function rectIn(root, item) {
    const topLeft = item.mapToItem(root, 0, 0)
    return { x: topLeft.x, y: topLeft.y, width: item.width, height: item.height }
}

// Picks the candidate that lies in the arrow's direction, preferring the one straight ahead.
function pick(root, from, candidates, dx, dy) {
    const origin = rectIn(root, from)
    const ox = origin.x + origin.width / 2
    const oy = origin.y + origin.height / 2
    let best = null
    let bestScore = Infinity
    for (const candidate of candidates) {
        if (candidate === from || contains(candidate, from) || contains(from, candidate)) continue
        const rect = rectIn(root, candidate)
        const cx = rect.x + rect.width / 2
        const cy = rect.y + rect.height / 2
        const along = dx !== 0 ? (cx - ox) * dx : (cy - oy) * dy
        const across = Math.abs(dx !== 0 ? cy - oy : cx - ox)
        // A neighbour has to be mostly ahead of the origin, not merely beside it.
        const overlap = dx !== 0
            ? Math.min(origin.y + origin.height, rect.y + rect.height) - Math.max(origin.y, rect.y)
            : Math.min(origin.x + origin.width, rect.x + rect.width) - Math.max(origin.x, rect.x)
        // Left and Right stay in their row; Up and Down may drift sideways, so a grid column can narrow to one card.
        if (along <= 1 || (dx !== 0 && overlap <= 0) || (overlap <= 0 && across > along)) continue
        const score = along + across * 2
        if (score < bestScore) {
            bestScore = score
            best = candidate
        }
    }
    return best
}

function scrollIntoView(item) {
    const margin = 12
    for (let parent = item.parent; parent; parent = parent.parent) {
        if (parent.contentItem === undefined || parent.contentY === undefined) continue
        const rect = item.mapToItem(parent.contentItem, 0, 0)
        const top = rect.y - margin
        const bottom = rect.y + item.height + margin
        const limit = Math.max(0, parent.contentHeight - parent.height)
        if (top < parent.contentY) parent.contentY = Math.max(0, top)
        else if (bottom > parent.contentY + parent.height) parent.contentY = Math.min(limit, bottom - parent.height)
    }
}

function scrollable(root, found = []) {
    for (const child of root.children) {
        if (!child.visible || child.opacity <= 0) continue
        if (child.contentY !== undefined && child.contentItem !== undefined && child.contentHeight > child.height + 1)
            found.push(child)
        scrollable(child, found)
    }
    return found
}

// Up and Down scroll a panel's content when there is nothing focusable to step to.
function scrollFallback(root, dy) {
    if (dy === 0) return false
    const view = scrollable(root)[0]
    if (!view) return false
    const limit = Math.max(0, view.contentHeight - view.height)
    const next = Math.max(0, Math.min(limit, view.contentY + dy * Math.max(48, view.height * 0.2)))
    if (next === view.contentY) return false
    view.contentY = next
    return true
}

function inHeader(item) {
    for (let parent = item.parent; parent; parent = parent.parent) {
        if (parent.panelHeader) return true
    }
    return false
}

// Where the first arrow press lands: the top-left control of the panel's content (the bottom-right one going
// back), reading left to right and top to bottom, with the header's buttons only as a last resort.
function entry(root, candidates, forward) {
    const content = candidates.filter(candidate => !inHeader(candidate))
    const pool = content.length > 0 ? content : candidates
    const order = pool.map(candidate => {
        const rect = rectIn(root, candidate)
        return { candidate, row: Math.round((rect.y + rect.height / 2) / 24), x: rect.x }
    }).sort((a, b) => a.row - b.row || a.x - b.x)
    return (forward ? order[0] : order[order.length - 1]).candidate
}

// Moves keyboard focus one step in the arrow's direction under root. Returns whether focus moved or a
// target was found; false leaves the key to whoever wants it.
function move(root, current, dx, dy) {
    const candidates = collect(root)
    if (candidates.length === 0) return scrollFallback(root, dy)
    // A focused list or grid is the origin even though it is not a stop itself; only an unfocused panel starts at the entry.
    let from = current
    while (from && from !== root && !candidates.includes(from) && !from.keyNavigationEnabled) from = from.parent
    if (from && from !== root && !inside(root, from)) from = null
    let target = null
    if (from && from !== root) {
        target = pick(root, from, candidates, dx, dy)
        // Past the last item of a line there is nothing further: scroll if there is more, else stay put.
        if (!target) {
            scrollFallback(root, dy)
            return true
        }
    } else {
        target = entry(root, candidates, dx + dy > 0)
    }
    target.forceActiveFocus(Qt.TabFocusReason)
    scrollIntoView(target)
    return true
}
