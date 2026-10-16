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
    "launcher", "menu", "appearance", "desktop", "displays", "clock", "lock", "osd", "workspaces",
    "dynamicPalette", "notifications", "interaction", "wallpaperAnimation", "media", "screenRecording"
];

assert.deepEqual(JSON.parse(JSON.stringify(registry.settingsSections.map(section => section.key))), expectedSections);

for (const section of registry.settingsSections) {
    const entry = registry.findEntryById(`settings-${section.key}`);
    assert.ok(entry, `settings section ${section.key} has a menu entry`);
    assert.deepEqual(JSON.parse(JSON.stringify(entry.route)), { type: "settings", section: section.key });
    assert.equal(entry.title, `Settings > ${section.title}`, `${section.key} menu entry is labelled by its parent panel`);
}
for (const entry of registry.menuEntries.filter(entry => entry.route.type !== "settings"))
    assert.ok(!entry.title.startsWith("Settings >"), `${entry.id} is not a settings page`);

assert.ok(registry.menuEntries.filter(entry => entry.route.type === "settings").every(entry => entry.searchOnly), "settings pages are search-only");

const timerEntry = registry.findEntryById("timer");
assert.ok(timerEntry && timerEntry.title === "Timer" && timerEntry.route.action === "openTimer", "the menu offers the timer panel");
for (const query of ["timer", "countdown", "alarm", "pomodoro"])
    assert.ok(registry.filterEntries(query).some(entry => entry.id === "timer"), `${query} finds the timer`);
assert.ok(registry.filterEntries("").every(entry => entry.route.type !== "settings"), "blank search hides settings pages");
assert.ok(registry.filterEntries("settings").filter(entry => entry.route.type === "settings").length === expectedSections.length, "a query lists every settings page");
assert.deepEqual(JSON.parse(JSON.stringify(registry.filterEntries("", undefined, ["settings-clock", "themes"]).slice(0, 2).map(entry => entry.id))), ["settings-clock", "themes"], "pinned settings pages stay visible");
assert.ok(registry.browsableIds().every(id => registry.findEntryById(id).route.type !== "settings"), "browsing never offers settings pages");
assert.ok(registry.chooseDisplayedIds([], undefined, 16, () => 0.5).every(id => registry.findEntryById(id).route.type !== "settings"), "default grid fill skips settings pages");

const sectionKeys = query => JSON.parse(JSON.stringify(registry.filterSettingsSections(query).map(section => section.key)));
assert.equal(sectionKeys("").length, expectedSections.length, "empty settings query lists every section");
assert.deepEqual(sectionKeys("LOCKSCREEN blur"), ["lock"], "settings search spans keywords and ignores case");
assert.ok(sectionKeys("monitors").includes("displays"), "settings search matches descriptions");
assert.ok(sectionKeys("record").includes("screenRecording"), "settings search finds screen recording");
assert.ok(sectionKeys("settings").length === 0, "settings search does not match the menu-only prefix");
assert.deepEqual(sectionKeys("zzzz"), [], "settings search returns nothing for unknown terms");

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
for (const query of ["system stats", "statistics", "hardware", "cpu", "memory", "ram", "uptime"])
    assert.ok(registry.filterEntries(query).some(entry => entry.id === "system"), `System can be found by ${query}`);
assert.ok(registry.filterEntries("provider credits").some(entry => entry.id === "ai-usage"), "AI Usage can be found by provider keywords");
assert.ok(registry.filterEntries("anthropic").some(entry => entry.id === "ai-usage"), "AI Usage can be found by provider names");
for (const query of ["bluetooth", "headphones", "pairing"])
    assert.ok(registry.filterEntries(query).some(entry => entry.id === "bluetooth"), `Bluetooth can be found by ${query}`);
for (const query of ["battery performance profile", "power profile", "battery", "power saver", "balanced", "performance"])
    assert.ok(registry.filterEntries(query).some(entry => entry.id === "power-profile"), `Power profile can be found by ${query}`);
for (const query of ["protonvpn", "proton vpn", "vpn", "kill switch", "country"])
    assert.ok(registry.filterEntries(query).some(entry => entry.id === "proton-vpn"), `Proton VPN can be found by ${query}`);
assert.equal(registry.findEntryById("power-profile").route.action, "openPowerProfile", "Power profile opens its own panel");
assert.equal(registry.findEntryById("proton-vpn").route.action, "openProtonVpn", "Proton VPN opens its own panel");
for (const query of ["clipboard", "cliphist", "paste", "copy history"])
    assert.ok(registry.filterEntries(query).some(entry => entry.id === "clipboard"), `Clipboard can be found by ${query}`);
for (const query of ["chromack", "color picker", "eyedropper", "hex", "shades", "color theory"])
    assert.ok(registry.filterEntries(query).some(entry => entry.id === "chromack"), `Chromack can be found by ${query}`);
for (const query of ["browse wallpapers", "wallhaven", "pastel", "generate palette", "toplist", "online"])
    assert.ok(registry.filterEntries(query).some(entry => entry.id === "browse-wallpapers"), `Browse Wallpapers can be found by ${query}`);
assert.equal(registry.findEntryById("browse-wallpapers").title, "Browse Wallpapers", "Browse Wallpapers keeps its exact menu title");
assert.equal(registry.findEntryById("browse-wallpapers").route.action, "openWallhaven", "Browse Wallpapers opens the Wallhaven panel");
assert.equal(JSON.stringify(allEntries), allBeforeSearch, "search does not mutate the registry");
assert.deepEqual(JSON.parse(JSON.stringify(registry.filterEntries("", undefined, ["launcher", "settings"]).slice(0, 3).map(entry => entry.id))), ["launcher", "settings", "themes"], "pinned entries lead search results in pin order");
assert.deepEqual(JSON.parse(JSON.stringify(registry.filterEntries("session", undefined, ["launcher"]).map(entry => entry.id))), ["session"], "pinned entries that do not match the query stay hidden");

const invalidPins = inRegistry('["themes", "missing", "themes", null, "settings", "shell-mode", "launcher", "system"]');
const invalidPinsBefore = JSON.stringify(invalidPins);
assert.deepEqual(JSON.parse(JSON.stringify(registry.sanitizePinnedIds(invalidPins))), ["themes", "settings", "shell-mode", "launcher", "system"]);
const allIds = inRegistry('menuEntries.map(entry => entry.id)');
assert.equal(registry.sanitizePinnedIds(allIds).length, 16, "pins are capped at a full 4x4 grid");
for (const [value, expected] of [[undefined, 2], ["", 2], [1, 2], [2, 2], [3, 3], [3.7, 3], [4, 4], [9, 4], ["4", 4], ["bad", 2]])
    assert.equal(registry.gridSize(value), expected, `grid size ${value} clamps to ${expected}`);
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
assert.equal(registry.chooseDisplayedIds([], allIds, 16, randomizeToKeepOrder).length, 16, "a 4x4 grid fills sixteen cards");
assert.equal(registry.chooseDisplayedIds([], allIds, 99, randomizeToKeepOrder).length, 16, "card limit is capped at sixteen");

const listed = toPlainIds(registry.listDisplayedIds(inRegistry('["themes"]'), eligible, undefined));
assert.deepEqual(listed, ["themes", ...eligible], "the unsearched grid lists pins first, then every eligible entry");
assert.deepEqual(toPlainIds(registry.listDisplayedIds(inRegistry('["themes", "settings"]'), eligible, inRegistry('["themes", "wallpapers"]'))), ["themes", "wallpapers", "settings", "shell-mode"], "unavailable pins are dropped but eligible entries are kept");
assert.equal(registry.listDisplayedIds([], undefined, undefined).length, registry.browsableIds().length, "the default list covers every browsable entry");
function toPlainIds(value) { return JSON.parse(JSON.stringify(value)); }

const toPlain = value => JSON.parse(JSON.stringify(value));
const pinOrder = inRegistry('["themes", "wallpapers", "settings", "shell-mode"]');
const pinOrderBefore = JSON.stringify(pinOrder);
assert.deepEqual(toPlain(registry.movePinnedId(pinOrder, "themes", 2)), ["wallpapers", "settings", "themes", "shell-mode"], "pin moves forward");
assert.deepEqual(toPlain(registry.movePinnedId(pinOrder, "shell-mode", 0)), ["shell-mode", "themes", "wallpapers", "settings"], "pin moves backward");
assert.deepEqual(toPlain(registry.movePinnedId(pinOrder, "settings", 2)), ["themes", "wallpapers", "settings", "shell-mode"], "pin at its own index is a no-op");
assert.deepEqual(toPlain(registry.movePinnedId(pinOrder, "settings", -5)), ["settings", "themes", "wallpapers", "shell-mode"], "target index clamps below zero");
assert.deepEqual(toPlain(registry.movePinnedId(pinOrder, "themes", 99)), ["wallpapers", "settings", "shell-mode", "themes"], "target index clamps above length");
assert.deepEqual(toPlain(registry.movePinnedId(pinOrder, "launcher", 0)), ["themes", "wallpapers", "settings", "shell-mode"], "unpinned id leaves order unchanged");
for (const index of ["2", NaN, Infinity, undefined, null])
    assert.deepEqual(toPlain(registry.movePinnedId(pinOrder, "themes", index)), ["themes", "wallpapers", "settings", "shell-mode"], `non-numeric index ${String(index)} leaves order unchanged`);
assert.notEqual(registry.movePinnedId(pinOrder, "launcher", 0), pinOrder, "unchanged move returns a new array");
assert.equal(JSON.stringify(pinOrder), pinOrderBefore, "move does not mutate pinned input");

console.log("PASS: menu registry routes, assets, labels, search, pins, deterministic random fill, cached order, and input immutability");
