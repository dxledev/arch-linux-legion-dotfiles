#!/usr/bin/env node

"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const islandRoot = path.resolve(__dirname, "../..");
const registryPath = path.join(islandRoot, "services/MenuEntries.js");
const registrySource = fs.readFileSync(registryPath, "utf8").replace(/^\.pragma library\s*/, "");
const registry = {};
vm.runInNewContext(registrySource, registry, { filename: registryPath });
const inRegistry = expression => vm.runInNewContext(expression, registry);

const controllerPath = path.join(islandRoot, "core/IslandController.qml");
const controllerSource = fs.readFileSync(controllerPath, "utf8");
const controllerActions = new Set(Array.from(controllerSource.matchAll(/function\s+(\w+)\s*\(/g), match => match[1]));
const expectedSections = [
    "launcher", "appearance", "displays", "clock", "lock", "osd", "workspaces",
    "dynamicPalette", "notifications", "interaction", "wallpaperAnimation"
];

assert.deepEqual(JSON.parse(JSON.stringify(registry.settingsSections.map(section => section.key))), expectedSections);

for (const section of registry.settingsSections) {
    const entry = registry.findEntryById(`settings-${section.key}`);
    assert.ok(entry, `settings section ${section.key} has a menu entry`);
    assert.deepEqual(JSON.parse(JSON.stringify(entry.route)), { type: "settings", section: section.key });
}

for (const entry of registry.menuEntries) {
    assert.ok(entry.title.trim(), `${entry.id} has a title`);
    assert.ok(entry.subtitle.trim(), `${entry.id} has a description`);
    assert.ok(fs.existsSync(path.resolve(path.dirname(registryPath), entry.icon)), `${entry.id} icon exists: ${entry.icon}`);
    if (entry.route.type === "controller")
        assert.ok(controllerActions.has(entry.route.action), `${entry.id} controller action exists: ${entry.route.action}`);
    else
        assert.ok(expectedSections.includes(entry.route.section), `${entry.id} maps to a direct settings route`);

    assert.ok(registry.filterEntries(entry.title.toUpperCase()).some(match => match.id === entry.id), `${entry.id} is searchable by title`);
    assert.ok(registry.filterEntries(entry.subtitle.toUpperCase()).some(match => match.id === entry.id), `${entry.id} is searchable by description`);
}

assert.deepEqual(JSON.parse(JSON.stringify(registry.menuEntries.slice(0, 4).map(({ id, title, subtitle }) => ({ id, title, subtitle })))), [
    { id: "themes", title: "Themes", subtitle: "Colors and palettes" },
    { id: "wallpapers", title: "Wallpapers", subtitle: "Choose your backdrop" },
    { id: "settings", title: "Settings", subtitle: "Make Island yours" },
    { id: "shell-mode", title: "Shell mode", subtitle: "Switch your workspace" }
]);

const allEntries = registry.menuEntries;
const allBeforeSearch = JSON.stringify(allEntries);
assert.ok(registry.filterEntries("MoNiToRs workspaces").some(entry => entry.id === "settings-displays"), "multi-term search spans description and ignores case");
assert.ok(registry.filterEntries("wallpaper colors").some(entry => entry.id === "settings-dynamicPalette"), "multi-term search includes keywords");
assert.ok(registry.filterEntries("LOCKSCREEN blur").some(entry => entry.id === "settings-lock"), "multi-term search finds settings keywords");
assert.equal(JSON.stringify(allEntries), allBeforeSearch, "search does not mutate the registry");

const invalidPins = inRegistry('["themes", "missing", "themes", null, "settings", "shell-mode", "launcher", "system"]');
const invalidPinsBefore = JSON.stringify(invalidPins);
assert.deepEqual(JSON.parse(JSON.stringify(registry.sanitizePinnedIds(invalidPins))), ["themes", "settings", "shell-mode", "launcher"]);
assert.equal(JSON.stringify(invalidPins), invalidPinsBefore, "pin sanitizing does not mutate input");
const nonPinnableEntries = inRegistry('menuEntries.map(entry => entry.id === "settings-launcher" ? Object.assign({}, entry, { pinnable: false }) : entry)');
assert.deepEqual(JSON.parse(JSON.stringify(registry.sanitizePinnedIds(inRegistry('["settings-launcher", "themes"]'), nonPinnableEntries))), ["themes"], "non-pinnable entries are discarded");

const pins = inRegistry('["themes"]');
const eligible = inRegistry('["wallpapers", "settings", "shell-mode"]');
const pinsBefore = JSON.stringify(pins);
const eligibleBefore = JSON.stringify(eligible);
const randomizeToReverse = () => 0;
const randomizeToKeepOrder = () => 0.999;
const randomized = registry.chooseDisplayedIds(pins, eligible, 4, randomizeToReverse);
assert.deepEqual(JSON.parse(JSON.stringify(randomized)), ["themes", "settings", "shell-mode", "wallpapers"]);
assert.deepEqual(JSON.parse(JSON.stringify(registry.chooseDisplayedIds(pins, eligible, 4, randomizeToKeepOrder))), ["themes", ...eligible]);
assert.notDeepEqual(JSON.parse(JSON.stringify(randomized.slice(1))), eligible, "filler selection can randomize");
assert.deepEqual(JSON.parse(JSON.stringify(registry.chooseDisplayedIds(pins, eligible, 4, randomizeToReverse, false))), ["themes", ...eligible], "cached eligible order stays stable");
assert.deepEqual(JSON.parse(JSON.stringify(registry.chooseDisplayedIds(inRegistry('["themes", "themes"]'), inRegistry('["themes", "wallpapers", "wallpapers"]'), 4, randomizeToKeepOrder))), ["themes", "wallpapers"], "fillers exclude pinned and duplicate IDs");
assert.equal(JSON.stringify(pins), pinsBefore, "chooser does not mutate pinned input");
assert.equal(JSON.stringify(eligible), eligibleBefore, "chooser does not mutate eligible input");

console.log("PASS: menu registry routes, assets, labels, search, pins, deterministic random fill, cached order, and input immutability");
