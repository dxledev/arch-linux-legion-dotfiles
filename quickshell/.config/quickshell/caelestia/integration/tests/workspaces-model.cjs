const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const sourcePath = path.resolve(__dirname, "../../services/WorkspaceModel.js");
const source = fs.readFileSync(sourcePath, "utf8").replace(/^\.pragma library\s*\n/, "");
const library = {};
vm.runInNewContext(source, library, { filename: sourcePath });
const visibleIds = (...args) => Array.from(library.visibleIds(...args));

const hdmi = { id: 0, name: "HDMI-A-1", description: "HDMI panel", activeWorkspace: { id: 4 } };
const dp = { id: 1, name: "DP-1", description: "DP panel", activeWorkspace: { id: 10 } };
const edp = { id: 2, name: "eDP-2", description: "BOE 0x0A2D", activeWorkspace: { id: 12 } };
const rules = [
    ...[1, 2, 3, 4, 5].map(id => ({ workspaceString: String(id), enabled: true, monitor: "HDMI-A-1", persistent: true })),
    ...[6, 7, 8, 9].map(id => ({ workspaceString: String(id), enabled: true, monitor: "HDMI-A-1", persistent: false })),
    { workspaceString: "10", enabled: true, monitor: "DP-1", persistent: true },
    { workspaceString: "11", enabled: true, monitor: "1", persistent: true },
    { workspaceString: "12", enabled: true, monitor: "desc:BOE", persistent: true }
];
const workspaces = [
    ...[1, 2, 3, 4, 5].map(id => ({ id, monitor: "HDMI-A-1", ispersistent: true, windows: 0 })),
    ...[6, 7, 8, 9].map(id => ({ id, monitor: "HDMI-A-1", ispersistent: false, windows: 1 })),
    { id: 10, monitor: "DP-1", ispersistent: true, windows: 0 },
    { id: 11, monitor: "DP-1", ispersistent: true, windows: 0 },
    { id: 12, monitor: "eDP-2", ispersistent: true, windows: 0 }
];

assert.deepEqual(visibleIds(hdmi, workspaces, rules, 5, 1, true), [1, 2, 3, 4, 5]);
assert.deepEqual(visibleIds(dp, workspaces, rules, 5, 1, true), [10, 11]);
assert.deepEqual(visibleIds(edp, workspaces, rules, 5, 1, true), [12]);

assert.deepEqual(
    visibleIds(hdmi, [], rules, 5, 1, true),
    [1, 2, 3, 4, 5],
    "persistent rules remain visible when live persistent workspace records are missing"
);

assert.deepEqual(
    visibleIds(hdmi, [], [...rules, { workspaceString: "13", monitor: "HDMI-A-1", persistent: true }], 5, 1, true),
    [1, 2, 3, 4, 5, 13],
    "rules without an enabled field remain active"
);

assert.deepEqual(
    visibleIds(
        hdmi,
        [{ id: 15, monitor: "HDMI-A-1", ispersistent: true, windows: 0 }],
        [{ workspaceString: "15", monitor: "HDMI-A-1" }],
        5,
        1,
        true
    ),
    [15],
    "monitor-only rules preserve the live persistent workspace state"
);

const duplicateRules = [
    { workspaceString: "16", enabled: true, monitor: "HDMI-A-1", persistent: true },
    { workspaceString: "16", enabled: true, monitor: "DP-1", persistent: true }
];
assert.deepEqual(visibleIds(dp, [], duplicateRules, 5, 1, true), [16]);
assert.deepEqual(visibleIds(hdmi, [], duplicateRules, 5, 1, true), [1, 2, 3, 4, 5]);
assert.deepEqual(
    visibleIds(dp, [], [...duplicateRules, { workspaceString: "16", enabled: false, monitor: "HDMI-A-1", persistent: false }], 5, 1, true),
    [16],
    "disabled duplicates do not override the last enabled binding"
);
assert.deepEqual(
    visibleIds(
        dp,
        [{ id: 16, monitor: "DP-1", ispersistent: true, windows: 0 }],
        [...duplicateRules, { workspaceString: "16", enabled: true, monitor: "DP-1", persistent: false }],
        5,
        1,
        true
    ).includes(16),
    false,
    "the last enabled nonpersistent binding overrides earlier duplicate rules and live state"
);

const noncontiguous = [
    { id: 2, monitor: "HDMI-A-1", ispersistent: true, windows: 0 },
    { id: 8, monitor: "HDMI-A-1", ispersistent: true, windows: 0 },
    { id: 14, monitor: "DP-1", ispersistent: true, windows: 0 }
];
assert.deepEqual(visibleIds(hdmi, noncontiguous, [], 5, 1, true), [2, 8]);

const manyPersistent = Array.from({ length: 7 }, (_, index) => ({
    id: index * 3 + 1,
    monitor: "HDMI-A-1",
    ispersistent: true,
    windows: 0
}));
assert.deepEqual(visibleIds(hdmi, manyPersistent, [], 5, 1, true), [1, 4, 7, 10, 13, 16, 19]);

const fallbackWorkspaces = [
    { id: 1, monitor: "HDMI-A-1", ispersistent: false, windows: 1 },
    { id: 2, monitor: "HDMI-A-1", ispersistent: false, windows: 1 },
    { id: 3, monitor: "HDMI-A-1", ispersistent: false, windows: 0 },
    { id: 6, monitor: "DP-1", ispersistent: false, windows: 1 },
    { id: 7, monitor: "DP-1", ispersistent: false, windows: 0 }
];
const fallbackRules = [
    { workspaceString: "1", enabled: true, monitor: "HDMI-A-1", persistent: false },
    { workspaceString: "6", enabled: true, monitor: "DP-1", persistent: false },
    { workspaceString: "7", enabled: true, monitor: "desc:DP panel", persistent: false },
    { workspaceString: "8", enabled: false, monitor: "DP-1", persistent: true },
    { workspaceString: "-2", enabled: true, monitor: "DP-1", persistent: true },
    { workspaceString: "special:foo", enabled: true, monitor: "DP-1", persistent: true }
];
assert.deepEqual(
    visibleIds(hdmi, fallbackWorkspaces, fallbackRules, 5, 1, true),
    [1, 2, 3, 4, 5],
    "fallback keeps HDMI workspaces while avoiding foreign live and pinned IDs"
);

const fallbackNoSteal = [
    ...Array.from({ length: 11 }, (_, index) => ({
        workspaceString: String(index + 1),
        enabled: true,
        monitor: "DP-1",
        persistent: false
    }))
];
assert.deepEqual(
    visibleIds(edp, [], fallbackNoSteal, 5, 1, true),
    [12, 13, 14, 15, 16],
    "fallback avoids numeric IDs assigned to another monitor even without live workspaces"
);

const arbitraryMonitors = [
    { id: 3, name: "DP-7", description: "DisplayPort seven" },
    { id: 4, name: "HDMI-A-3", description: "Acme HDMI-A-3 panel" },
    { id: 6, name: "eDP-1", description: "Laptop panel" },
    { id: 7, name: "Virtual-1", description: "Virtual output" }
];
const arbitraryRules = [
    { workspaceString: "30", monitor: "DP-7", persistent: true },
    { workspaceString: "41", monitor: "desc:Acme HDMI", persistent: true },
    { workspaceString: "52", monitor: "6", persistent: true },
    { workspaceString: "63", monitor: "Virtual-1", persistent: true }
];
assert.deepEqual(visibleIds(arbitraryMonitors[0], [], arbitraryRules, 5, 1, true), [30]);
assert.deepEqual(visibleIds(arbitraryMonitors[1], [], arbitraryRules, 5, 1, true), [41]);
assert.deepEqual(visibleIds(arbitraryMonitors[2], [], arbitraryRules, 5, 1, true), [52]);
assert.deepEqual(visibleIds(arbitraryMonitors[3], [], arbitraryRules, 5, 1, true), [63]);

const arbitraryLivePersistent = [
    { id: 17, monitor: "Virtual-1", ispersistent: true, windows: 0 },
    { id: 29, monitor: "Virtual-1", ispersistent: true, windows: 0 },
    { id: 18, monitor: "DP-7", ispersistent: true, windows: 0 }
];
assert.deepEqual(
    visibleIds(arbitraryMonitors[3], arbitraryLivePersistent, [], 5, 1, true),
    [17, 29],
    "noncontiguous live persistence works for an unconfigured connector name"
);

const virtualFallback = { ...arbitraryMonitors[3], activeWorkspace: { id: 0 } };
assert.deepEqual(visibleIds(virtualFallback, [], [], 0, 1, true), [1, 2, 3, 4, 5]);
assert.deepEqual(visibleIds(virtualFallback, [], [], 2, 7, true), [7, 8, 9, 10, 11]);
assert.deepEqual(visibleIds(virtualFallback, [], [], 8, 1, true), [1, 2, 3, 4, 5, 6, 7, 8]);

const disconnectedReservations = [
    ...Array.from({ length: 5 }, (_, index) => ({
        workspaceString: String(index + 1),
        monitor: "DP-7",
        persistent: false
    })),
    ...Array.from({ length: 6 }, (_, index) => ({
        workspaceString: String(index + 6),
        monitor: "HDMI-A-3",
        persistent: false
    }))
];
assert.deepEqual(
    visibleIds(virtualFallback, [], disconnectedReservations, 0, 1, true),
    [12, 13, 14, 15, 16],
    "fallback reserves IDs owned by monitors with no live workspace records"
);

const hotplugRules = [
    { workspaceString: "30", monitor: "DP-7", persistent: true },
    { workspaceString: "31", monitor: "DP-7", persistent: false }
];
const hotplugWorkspaces = [
    { id: 30, monitor: "DP-7", ispersistent: true, windows: 0 },
    { id: 31, monitor: "DP-7", ispersistent: false, windows: 0 }
];
const dp7 = { ...arbitraryMonitors[0], activeWorkspace: { id: 30 } };
const virtual1 = { ...arbitraryMonitors[3], activeWorkspace: { id: 0 } };
assert.deepEqual(visibleIds(dp7, hotplugWorkspaces, hotplugRules, 5, 30, true), [30]);
assert.deepEqual(visibleIds(undefined, [], hotplugRules, 5, 30, true), []);
assert.deepEqual(
    visibleIds(virtual1, [], hotplugRules, 5, 30, true),
    [32, 33, 34, 35, 36],
    "a newly connected monitor skips IDs reserved by a disconnected connector"
);

const reassignedRules = [
    { workspaceString: "30", monitor: "Virtual-1", persistent: true },
    { workspaceString: "31", monitor: "DP-7", persistent: false }
];
const reassignedWorkspaces = [
    { id: 30, monitor: "DP-7", ispersistent: false, windows: 1 },
    { id: 31, monitor: "DP-7", ispersistent: false, windows: 0 }
];
assert.deepEqual(visibleIds(virtual1, reassignedWorkspaces, reassignedRules, 5, 30, true), [30]);
assert.equal(
    visibleIds(dp7, reassignedWorkspaces, reassignedRules, 5, 30, true).includes(30),
    false,
    "the latest assignment moves a persistent ID between arbitrary connectors"
);

assert.deepEqual(visibleIds(undefined, workspaces, rules, 5, 1, true), []);
assert.deepEqual(
    visibleIds(undefined, workspaces, rules, 5, 1, false),
    [1, 2, 3, 4, 5, 10, 11, 12],
    "global mode aggregates persistent workspaces from every monitor"
);

const globalFallback = [
    { id: 20, monitor: "DP-1", ispersistent: false, windows: 1 },
    { id: -1, monitor: "DP-1", ispersistent: false, windows: 1 },
    { id: "special:current", monitor: "HDMI-A-1", ispersistent: false, windows: 1 }
];
assert.deepEqual(
    visibleIds(hdmi, globalFallback, [], 7, 3, false),
    [3, 4, 5, 6, 7, 8, 20],
    "global fallback includes occupied positive IDs and meets configured count"
);

console.log("WorkspaceModel regression cases passed");
