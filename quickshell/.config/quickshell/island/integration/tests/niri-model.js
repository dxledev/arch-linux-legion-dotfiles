#!/usr/bin/env node

"use strict";

// Checks services/NiriModel.js: compositor detection, the niri event stream reducer, and the conversion to the
// Hyprland-shaped records the workspace views and the recorder consume. Run: node island/integration/tests/niri-model.js

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const islandRoot = path.resolve(__dirname, "../..");
function load(file) {
    const sourcePath = path.join(islandRoot, "services", file);
    const context = {};
    vm.runInNewContext(fs.readFileSync(sourcePath, "utf8").replace(/^\.pragma library\s*/, ""), context, { filename: sourcePath });
    return context;
}
const niri = load("NiriModel.js");
const targets = load("RecordTargets.js");
const plain = value => JSON.parse(JSON.stringify(value));

// --- Detection: the desktop name wins over inherited socket variables --------------------------------------
assert.equal(niri.detect({ desktop: "niri", niriSocket: "/run/niri.sock" }), "niri");
assert.equal(niri.detect({ desktop: "Hyprland", hyprlandSignature: "abc" }), "hyprland");
assert.equal(niri.detect({ desktop: "Hyprland", niriSocket: "/stale/niri.sock", hyprlandSignature: "abc" }), "hyprland");
assert.equal(niri.detect({ desktop: "niri", hyprlandSignature: "inherited" }), "niri");
assert.equal(niri.detect({ desktop: "GNOME:niri" }), "niri");
assert.equal(niri.detect({ niriSocket: "/run/niri.sock" }), "niri");
assert.equal(niri.detect({ hyprlandSignature: "abc" }), "hyprland");
assert.equal(niri.detect({ niriSocket: "/run/niri.sock", hyprlandSignature: "abc" }), "hyprland", "Hyprland wins when nothing else tells them apart");
assert.equal(niri.detect({}), "none");
assert.equal(niri.detect({ override: "niri", desktop: "Hyprland", hyprlandSignature: "abc" }), "niri");
assert.equal(niri.detect({ override: "bogus", desktop: "Hyprland" }), "hyprland");
const variables = { ISLAND_COMPOSITOR: "", XDG_CURRENT_DESKTOP: "niri", NIRI_SOCKET: "", HYPRLAND_INSTANCE_SIGNATURE: "x" };
assert.equal(niri.detectWith(name => variables[name]), "niri");

// --- Event stream -----------------------------------------------------------------------------------------
const workspaces = [
    { id: 10, idx: 1, name: null, output: "HDMI-A-1", is_urgent: false, is_active: true, is_focused: true, active_window_id: 7 },
    { id: 11, idx: 2, name: "web", output: "HDMI-A-1", is_urgent: false, is_active: false, is_focused: false, active_window_id: null },
    { id: 20, idx: 1, name: null, output: "DP-1", is_urgent: false, is_active: true, is_focused: false, active_window_id: null }
];
const layout = (x, y) => ({ pos_in_scrolling_layout: [1, 1], tile_size: [700, 500], window_size: [696, 496], tile_pos_in_workspace_view: [x, y], window_offset_in_tile: [2, 2] });
const window = (id, workspaceId, extra = {}) => Object.assign({ id, title: "w" + id, app_id: "foot", pid: id, workspace_id: workspaceId, is_focused: false, is_floating: false, is_urgent: false, layout: layout(16, 16) }, extra);

let state = niri.emptyState();
const apply = message => {
    const result = niri.applyEvent(state, message);
    state = result.state;
    return result;
};

apply({ ConfigLoaded: { failed: false } });
apply({ WorkspacesChanged: { workspaces } });
apply({ WindowsChanged: { windows: [window(7, 10, { is_focused: true }), window(8, 11)] } });
assert.equal(niri.focusedOutput(state), "HDMI-A-1");

// Workspace models use the per-output index as the visible number and count their windows.
let models = niri.workspaceModels(state);
assert.deepEqual(plain(models.map(model => [model.monitor.name, model.id, model.name, model.lastIpcObject.windows, model.active, model.focused])),
    [["DP-1", 1, "1", 0, true, false], ["HDMI-A-1", 1, "1", 1, true, true], ["HDMI-A-1", 2, "web", 1, false, false]]);

// Activating a workspace on another output moves the focus and deactivates only that output's old workspace.
let result = apply({ WorkspaceActivated: { id: 20, focused: true } });
assert.equal(result.kind, "WorkspaceActivated");
assert.equal(result.focused, true);
assert.equal(niri.focusedOutput(state), "DP-1");
assert.deepEqual(state.workspaces.map(workspace => [workspace.id, workspace.is_active, workspace.is_focused]), [[10, true, false], [11, false, false], [20, true, true]]);
// Activating a hidden workspace of the first output replaces its active one but leaves the other output alone.
apply({ WorkspaceActivated: { id: 11, focused: false } });
assert.deepEqual(state.workspaces.map(workspace => [workspace.id, workspace.is_active, workspace.is_focused]), [[10, false, false], [11, true, false], [20, true, true]]);
apply({ WorkspaceActivated: { id: 10, focused: true } });

// Windows: opened, focused, laid out, urgent, closed.
result = apply({ WindowOpenedOrChanged: { window: window(9, 10, { is_focused: true }) } });
assert.equal(result.isNew, true);
assert.equal(state.windows[7].is_focused, false);
assert.equal(state.windows[9].is_focused, true);
result = apply({ WindowOpenedOrChanged: { window: window(9, 10, { is_focused: true, title: "renamed" }) } });
assert.equal(result.isNew, false);
apply({ WindowFocusChanged: { id: 7 } });
assert.deepEqual([7, 8, 9].map(id => state.windows[id].is_focused), [true, false, false]);
apply({ WindowFocusChanged: { id: null } });
assert.deepEqual([7, 8, 9].map(id => state.windows[id].is_focused), [false, false, false]);
apply({ WindowLayoutsChanged: { changes: [[7, layout(100, 50)]] } });
assert.deepEqual(plain(state.windows[7].layout.tile_pos_in_workspace_view), [100, 50]);
apply({ WindowUrgencyChanged: { id: 8, urgent: true } });
assert.equal(state.windows[8].is_urgent, true);
apply({ WindowClosed: { id: 9 } });
assert.equal(9 in state.windows, false);
assert.equal(niri.workspaceModels(state).find(model => model.niriId === 10).lastIpcObject.windows, 1);

// Keyboard layouts, overview and noise.
apply({ KeyboardLayoutsChanged: { keyboard_layouts: { names: ["English (US)", "Persian"], current_idx: 0 } } });
apply({ KeyboardLayoutSwitched: { idx: 1 } });
assert.equal(state.keyboard.names[state.keyboard.current_idx], "Persian");
apply({ OverviewOpenedOrClosed: { is_open: true } });
assert.equal(state.overviewOpen, true);
const before = state;
result = apply({ TouchpadToggled: { on: true } });
assert.equal(state, before, "unknown events leave the state untouched");
assert.equal(niri.applyEvent(state, null).kind, "");

// A spawn waits for a new window whose app id matches the hint.
const known = { 7: true, 8: true };
assert.equal(niri.matchesSpawn(window(12, 10, { app_id: "omafiles" }), known, "omafiles"), true);
assert.equal(niri.matchesSpawn(window(12, 10, { app_id: "OmaFiles" }), known, "omafiles"), true);
assert.equal(niri.matchesSpawn(window(12, 10, { app_id: null }), known, "omafiles"), false);
assert.equal(niri.matchesSpawn(window(7, 10, { app_id: "omafiles" }), known, "omafiles"), false, "an existing window is never the new one");
assert.equal(niri.matchesSpawn(window(13, 10, { app_id: "anything" }), known, ""), true);

// --- Monitors and the recorder's view of them ------------------------------------------------------------------
const outputs = {
    "HDMI-A-1": { name: "HDMI-A-1", make: "Acme", model: "Wide", serial: null, logical: { x: 0, y: 0, width: 1536, height: 864, scale: 1.25, transform: "Normal" } },
    "DP-1": { name: "DP-1", make: "Acme", model: "Tall", serial: "1", logical: { x: 1536, y: 0, width: 1440, height: 2560, scale: 1, transform: "90" } },
    "Off-1": { name: "Off-1", make: "x", model: "y", serial: null, logical: null }
};
const monitors = niri.monitorModels(outputs, niri.workspaceModels(state), niri.focusedOutput(state));
assert.equal(monitors["HDMI-A-1"].activeWorkspace.name, "1");
assert.equal(monitors["HDMI-A-1"].focused, true);
assert.equal(monitors["HDMI-A-1"].lastIpcObject.specialWorkspace.name, "", "niri has no special workspaces");
assert.equal(monitors["DP-1"].description, "Acme Tall 1");
assert.equal(niri.transformIndex("90"), 1);
assert.equal(niri.transformIndex("Flipped270"), 7);

const recordMonitors = niri.recordMonitors(outputs, niri.workspaceModels(state), niri.focusedOutput(state));
assert.deepEqual(plain(recordMonitors.map(monitor => [monitor.name, monitor.x, monitor.width, monitor.height, monitor.scale, monitor.transform])),
    [["DP-1", 1536, 1440, 2560, 1, 0], ["HDMI-A-1", 0, 1920, 1080, 1.25, 0]]);

// The recorder's own helpers accept those records: logical sizes come back out and windows land in global coordinates.
const screens = plain(targets.screens(recordMonitors));
assert.deepEqual(screens.map(screen => [screen.name, screen.width, screen.height]), [["DP-1", 1440, 2560], ["HDMI-A-1", 1536, 864]]);
const clients = niri.recordClients(state, outputs, niri.workspaceModels(state), recordMonitors);
assert.deepEqual(plain(clients.map(client => client.address)), ["7"], "only windows on a showing workspace with a view position are listed");
assert.deepEqual(plain(clients[0].at), [102, 52]);
assert.deepEqual(plain(clients[0].size), [696, 496]);
const targetWindows = plain(targets.windows(clients, recordMonitors));
assert.equal(targetWindows.length, 1);
assert.deepEqual([targetWindows[0].address, targetWindows[0].monitor, targetWindows[0].x, targetWindows[0].y, targetWindows[0].width, targetWindows[0].height],
    ["7", "HDMI-A-1", 102, 52, 696, 496]);

console.log("PASS: niri detection, event stream, workspace and monitor models, recorder records");
