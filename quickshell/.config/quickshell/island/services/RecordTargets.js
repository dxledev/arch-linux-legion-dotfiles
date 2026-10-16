.pragma library

// What the recording popup can capture, read from Hyprland's own `monitors` and `clients` data.
// Coordinates are the logical ones gpu-screen-recorder's -region expects (scaled monitors included).

function screens(monitors) {
    return (monitors ?? []).filter(monitor => monitor && monitor.name && monitor.width > 0 && monitor.height > 0).map(monitor => {
        const scale = monitor.scale > 0 ? monitor.scale : 1;
        // A rotated monitor swaps its sides in the layout.
        const turned = monitor.transform % 2 === 1;
        const width = (turned ? monitor.height : monitor.width) / scale;
        const height = (turned ? monitor.width : monitor.height) / scale;
        return {
            name: monitor.name, id: monitor.id, x: monitor.x, y: monitor.y, width: width, height: height,
            pixelWidth: monitor.width, pixelHeight: monitor.height, focused: monitor.focused === true
        };
    });
}

// Windows that are on screen right now (their workspace is showing on their monitor), most recently
// used first. A window on a hidden workspace cannot be recorded, so it is left out.
function windows(clients, monitors) {
    const byId = {};
    for (const monitor of monitors ?? []) if (monitor) byId[monitor.id] = monitor;
    const result = [];
    for (const client of clients ?? []) {
        if (!client || !client.mapped || client.hidden || !client.at || !client.size || !client.address) continue;
        const monitor = byId[client.monitor];
        const workspace = client.workspace?.id;
        if (!monitor || workspace === undefined) continue;
        if (workspace !== monitor.activeWorkspace?.id && workspace !== monitor.specialWorkspace?.id) continue;
        result.push({
            address: client.address,
            title: client.title || client.class || "Window",
            appClass: client.class || "",
            x: client.at[0], y: client.at[1], width: client.size[0], height: client.size[1],
            workspace: client.workspace.name,
            monitor: monitor.name,
            focusOrder: client.focusHistoryID ?? 0
        });
    }
    return result.sort((a, b) => a.focusOrder - b.focusOrder);
}

// The smallest rectangle holding every screen, for drawing them to scale.
function bounds(screenList) {
    if (!screenList || screenList.length === 0) return {x: 0, y: 0, width: 0, height: 0};
    let left = Infinity, top = Infinity, right = -Infinity, bottom = -Infinity;
    for (const screen of screenList) {
        left = Math.min(left, screen.x);
        top = Math.min(top, screen.y);
        right = Math.max(right, screen.x + screen.width);
        bottom = Math.max(bottom, screen.y + screen.height);
    }
    return {x: left, y: top, width: right - left, height: bottom - top};
}
