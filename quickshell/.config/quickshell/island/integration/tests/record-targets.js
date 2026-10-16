#!/usr/bin/env node

"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const islandRoot = path.resolve(__dirname, "../..");
const sourcePath = path.join(islandRoot, "services/RecordTargets.js");
const targets = {};
vm.runInNewContext(fs.readFileSync(sourcePath, "utf8").replace(/^\.pragma library\s*/, ""), targets, { filename: sourcePath });
const plain = value => JSON.parse(JSON.stringify(value));

const monitors = [
    { id: 0, name: "DP-1", x: 0, y: 0, width: 1920, height: 1080, scale: 1, transform: 0, focused: false, activeWorkspace: { id: 10 }, specialWorkspace: { id: 0 } },
    { id: 1, name: "HDMI-A-1", x: 1920, y: 0, width: 2560, height: 1440, scale: 1.25, transform: 0, focused: true, activeWorkspace: { id: 1 }, specialWorkspace: { id: -98 } }
];

// Scaled monitors are measured in the logical units gpu-screen-recorder's -region takes.
const screens = plain(targets.screens(monitors));
assert.deepEqual(screens.map(screen => [screen.name, screen.width, screen.height, screen.pixelWidth, screen.pixelHeight, screen.focused]),
    [["DP-1", 1920, 1080, 1920, 1080, false], ["HDMI-A-1", 2048, 1152, 2560, 1440, true]]);
assert.deepEqual(plain(targets.bounds(screens)), { x: 0, y: 0, width: 3968, height: 1152 });
assert.deepEqual(plain(targets.bounds([])), { x: 0, y: 0, width: 0, height: 0 });
assert.deepEqual(plain(targets.screens([{ name: "", width: 1, height: 1 }, null, { name: "X", width: 0, height: 1 }])), []);

// A rotated monitor swaps its sides.
assert.deepEqual(plain(targets.screens([{ id: 2, name: "R", x: 0, y: 0, width: 1920, height: 1080, scale: 1, transform: 1 }])).map(screen => [screen.width, screen.height]), [[1080, 1920]]);

const client = (address, workspace, monitor, extra = {}) => Object.assign({
    address, mapped: true, hidden: false, at: [10, 20], size: [300, 200], workspace: { id: workspace, name: String(workspace) },
    monitor, class: "kitty", title: "term " + address, focusHistoryID: 3
}, extra);
const clients = [
    client("0xa", 1, 1, { focusHistoryID: 2 }),
    client("0xb", 2, 1),                                   // hidden workspace: cannot be recorded
    client("0xc", 10, 0, { focusHistoryID: 0, title: "" }),
    client("0xd", 1, 1, { mapped: false }),
    client("0xe", 1, 1, { hidden: true }),
    client("0xf", -98, 1, { focusHistoryID: 1 }),          // on the special workspace showing on its monitor
    client("0x10", 1, 7)                                   // unknown monitor
];
const windows = plain(targets.windows(clients, monitors));
assert.deepEqual(windows.map(window => window.address), ["0xc", "0xf", "0xa"], "visible windows, most recently used first");
assert.equal(windows[0].title, "kitty", "an untitled window falls back to its class");
assert.deepEqual([windows[2].x, windows[2].y, windows[2].width, windows[2].height, windows[2].monitor], [10, 20, 300, 200, "HDMI-A-1"]);
assert.deepEqual(plain(targets.windows(null, null)), []);

console.log("PASS: recording targets use logical coordinates and list only visible windows");
