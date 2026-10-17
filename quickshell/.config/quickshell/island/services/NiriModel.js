.pragma library

// Everything Island needs to know about niri, kept free of QML so it can be tested on its own.
// niri's IPC (`niri msg --json ...`) is turned into the shapes the Hyprland code paths already consume:
// workspaces with `id`/`name`/`monitor.name`, monitors with `activeWorkspace`, and `hyprctl`-style
// `monitors`/`clients` records for the recorder.

// Which compositor Island runs under. `override` (ISLAND_COMPOSITOR) wins, then the session's
// XDG_CURRENT_DESKTOP, then whichever compositor socket variable is present (Hyprland's first). A nested niri inside
// Hyprland (or the reverse) inherits the other's variables, which is why the desktop name is read first.
function detect(env) {
    const forced = String(env.override || "").toLowerCase();
    if (forced === "niri" || forced === "hyprland") return forced;
    const desktops = String(env.desktop || "").toLowerCase().split(":");
    if (desktops.includes("niri")) return "niri";
    if (desktops.includes("hyprland")) return "hyprland";
    // Both sockets with no desktop name to tell them apart: Hyprland wins, so a stray variable never moves a
    // working Hyprland session onto niri. ISLAND_COMPOSITOR picks the other one for nested testing.
    if (env.hyprlandSignature) return "hyprland";
    if (env.niriSocket) return "niri";
    return "none";
}

// detect() fed from a `name => value` environment reader, so QML singletons share one definition.
function detectWith(getenv) {
    return detect({
        override: getenv("ISLAND_COMPOSITOR"),
        desktop: getenv("XDG_CURRENT_DESKTOP"),
        niriSocket: getenv("NIRI_SOCKET"),
        hyprlandSignature: getenv("HYPRLAND_INSTANCE_SIGNATURE")
    });
}

function emptyState() {
    return {
        workspaces: [],
        windows: {},
        keyboard: {names: [], current_idx: 0},
        overviewOpen: false,
        configFailed: false
    };
}

function copyWindows(windows) {
    return Object.assign({}, windows);
}

function setFocusedWindow(windows, id) {
    const next = copyWindows(windows);
    for (const key of Object.keys(next))
        if (next[key].is_focused !== (Number(key) === id))
            next[key] = Object.assign({}, next[key], {is_focused: Number(key) === id});
    return next;
}

// Applies one event-stream message and returns {state, kind, ...detail}. `state` is a new object when
// something changed; `kind` names the event so callers can react (a focused-workspace OSD, a new window).
function applyEvent(state, message) {
    const kind = message ? Object.keys(message)[0] : undefined;
    if (!kind) return {state: state, kind: ""};
    const data = message[kind] || {};
    const next = Object.assign({}, state);
    const result = {state: next, kind: kind};
    switch (kind) {
    case "WorkspacesChanged":
        next.workspaces = (data.workspaces || []).slice();
        break;
    case "WorkspaceActivated": {
        const target = state.workspaces.find(workspace => workspace.id === data.id);
        next.workspaces = state.workspaces.map(workspace => {
            const sameOutput = target && workspace.output === target.output;
            const active = sameOutput ? workspace.id === data.id : workspace.is_active;
            const focused = data.focused ? workspace.id === data.id : workspace.is_focused;
            return active === workspace.is_active && focused === workspace.is_focused
                ? workspace : Object.assign({}, workspace, {is_active: active, is_focused: focused});
        });
        result.workspaceId = data.id;
        result.focused = data.focused === true;
        break;
    }
    case "WorkspaceUrgencyChanged":
        next.workspaces = state.workspaces.map(workspace => workspace.id === data.id
            ? Object.assign({}, workspace, {is_urgent: data.urgent}) : workspace);
        break;
    case "WorkspaceActiveWindowChanged":
        next.workspaces = state.workspaces.map(workspace => workspace.id === data.workspace_id
            ? Object.assign({}, workspace, {active_window_id: data.active_window_id}) : workspace);
        break;
    case "WindowsChanged": {
        next.windows = {};
        for (const window of data.windows || []) next.windows[window.id] = window;
        break;
    }
    case "WindowOpenedOrChanged": {
        const window = data.window;
        if (!window) break;
        next.windows = window.is_focused ? setFocusedWindow(state.windows, -1) : copyWindows(state.windows);
        next.windows[window.id] = window;
        result.window = window;
        result.isNew = !(window.id in state.windows);
        break;
    }
    case "WindowClosed":
        next.windows = copyWindows(state.windows);
        delete next.windows[data.id];
        result.windowId = data.id;
        break;
    case "WindowFocusChanged":
        next.windows = setFocusedWindow(state.windows, data.id === null || data.id === undefined ? -1 : data.id);
        break;
    case "WindowUrgencyChanged":
        if (state.windows[data.id]) {
            next.windows = copyWindows(state.windows);
            next.windows[data.id] = Object.assign({}, state.windows[data.id], {is_urgent: data.urgent});
        }
        break;
    case "WindowLayoutsChanged":
        next.windows = copyWindows(state.windows);
        for (const change of data.changes || []) {
            const window = next.windows[change[0]];
            if (window) next.windows[change[0]] = Object.assign({}, window, {layout: change[1]});
        }
        break;
    case "KeyboardLayoutsChanged":
        next.keyboard = data.keyboard_layouts || state.keyboard;
        break;
    case "KeyboardLayoutSwitched":
        next.keyboard = Object.assign({}, state.keyboard, {current_idx: data.idx});
        break;
    case "OverviewOpenedOrClosed":
        next.overviewOpen = data.is_open === true;
        break;
    case "ConfigLoaded":
        next.configFailed = data.failed === true;
        break;
    default:
        // Casts, screenshots and touchpad events are not something Island shows.
        result.state = state;
    }
    return result;
}

// The output name of the focused workspace; "" until the first WorkspacesChanged arrives.
function focusedOutput(state) {
    return state.workspaces.find(workspace => workspace.is_focused)?.output ?? "";
}

function windowCount(state, workspaceId) {
    let count = 0;
    for (const key of Object.keys(state.windows))
        if (state.windows[key].workspace_id === workspaceId) count++;
    return count;
}

// Hyprland-shaped workspaces. niri workspaces are per output and positional, so `id` is the index on the
// output (what `niri msg action focus-workspace <n>` takes) and the stable niri id is kept as `niriId`.
function workspaceModels(state) {
    return state.workspaces.map(workspace => ({
        id: workspace.idx,
        niriId: workspace.id,
        name: workspace.name || String(workspace.idx),
        monitor: {name: workspace.output ?? ""},
        active: workspace.is_active === true,
        focused: workspace.is_focused === true,
        urgent: workspace.is_urgent === true,
        lastIpcObject: {windows: windowCount(state, workspace.id)}
    })).sort((a, b) => a.monitor.name < b.monitor.name ? -1 : a.monitor.name > b.monitor.name ? 1 : a.id - b.id);
}

// Hyprland-shaped monitors keyed by output name. `lastIpcObject.specialWorkspace` is always empty: niri has
// no special workspaces.
function monitorModels(outputs, workspaces, focusedName) {
    const result = {};
    for (const name of Object.keys(outputs || {})) {
        const output = outputs[name];
        const active = workspaces.find(workspace => workspace.monitor.name === name && workspace.active) ?? null;
        result[name] = {
            name: name,
            description: [output.make, output.model, output.serial].filter(part => part).join(" "),
            focused: name === focusedName,
            activeWorkspace: active,
            lastIpcObject: {specialWorkspace: {name: "", id: 0}, description: [output.make, output.model, output.serial].filter(part => part).join(" ")}
        };
    }
    return result;
}

function transformIndex(transform) {
    const names = ["Normal", "90", "180", "270", "Flipped", "Flipped90", "Flipped180", "Flipped270"];
    const index = names.indexOf(String(transform ?? "Normal"));
    return index < 0 ? 0 : index;
}

// `hyprctl monitors -j` records for the recorder. The logical size is already rotated and scaled, so the
// pixel width is the logical width times the scale and transform is reported as unrotated.
function recordMonitors(outputs, workspaces, focusedName) {
    const models = monitorModels(outputs, workspaces, focusedName);
    const result = [];
    let id = 0;
    for (const name of Object.keys(outputs || {}).sort()) {
        const output = outputs[name];
        const logical = output.logical;
        if (!logical) continue;
        const scale = logical.scale > 0 ? logical.scale : 1;
        result.push({
            id: id++, name: name, x: logical.x, y: logical.y,
            width: Math.round(logical.width * scale), height: Math.round(logical.height * scale),
            scale: scale, transform: 0, focused: models[name].focused,
            activeWorkspace: {id: models[name].activeWorkspace?.niriId ?? -1},
            specialWorkspace: {id: 0, name: ""}
        });
    }
    return result;
}

// `hyprctl clients -j` records for windows that are on screen. A window's place on its output is its tile's
// position in the workspace view plus the window's offset inside the tile; windows niri gives no view
// position (scrolled out of sight, on a hidden workspace) cannot be recorded and are left out.
function recordClients(state, outputs, workspaces, monitors) {
    const result = [];
    const monitorByName = {};
    for (const monitor of monitors) monitorByName[monitor.name] = monitor;
    const stamps = Object.keys(state.windows).map(key => state.windows[key].focus_timestamp)
        .filter(stamp => stamp && stamp.secs !== undefined);
    stamps.sort((a, b) => (b.secs - a.secs) || (b.nanos - a.nanos));
    for (const key of Object.keys(state.windows)) {
        const window = state.windows[key];
        const workspace = workspaces.find(candidate => candidate.niriId === window.workspace_id);
        const monitor = workspace ? monitorByName[workspace.monitor.name] : undefined;
        const layout = window.layout;
        if (!workspace || !workspace.active || !monitor || !layout || !layout.tile_pos_in_workspace_view) continue;
        const stamp = window.focus_timestamp;
        result.push({
            address: String(window.id), mapped: true, hidden: false,
            at: [Math.round(monitor.x + layout.tile_pos_in_workspace_view[0] + layout.window_offset_in_tile[0]),
                 Math.round(monitor.y + layout.tile_pos_in_workspace_view[1] + layout.window_offset_in_tile[1])],
            size: [layout.window_size[0], layout.window_size[1]],
            title: window.title || "", class: window.app_id || "",
            monitor: monitor.id, workspace: {id: workspace.niriId, name: workspace.name},
            focusHistoryID: stamp && stamp.secs !== undefined
                ? stamps.findIndex(candidate => candidate.secs === stamp.secs && candidate.nanos === stamp.nanos)
                : 1000
        });
    }
    return result;
}

// Matches a freshly opened window against the one a spawn is waiting for (see NiriService.spawnFloating).
function matchesSpawn(window, known, appIdHint) {
    if (!window || window.id in known) return false;
    if (!appIdHint) return true;
    return String(window.app_id || "").toLowerCase().includes(String(appIdHint).toLowerCase());
}
