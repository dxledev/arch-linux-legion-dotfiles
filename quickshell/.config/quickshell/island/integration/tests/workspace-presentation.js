#!/usr/bin/env node

"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const servicesDir = path.resolve(__dirname, "../../services");
const loadLibrary = filename => {
    const source = fs.readFileSync(path.join(servicesDir, filename), "utf8").replace(/^\.pragma library\s*/, "");
    const library = {};
    vm.runInNewContext(source, library, { filename });
    return library;
};

const presentation = loadLibrary("WorkspacePresentation.js");
const menuEntries = loadLibrary("MenuEntries.js");
const layouts = ["dwindle", "scrolling", "master", "monocle", "lua:grid", "lua:spiral", "lua:manual", "lua:centerstack"];
const ids = menuEntries.menuEntries.map(entry => entry.id);
const availableIds = ids.filter(id => id !== "workspace-axis");
const availableEntries = menuEntries.menuEntries.filter(entry => entry.id !== "workspace-axis");

assert.equal(presentation.normalizeLayout("grid"), "lua:grid", "Lua layout shorthand normalizes for active markers");
assert.equal(presentation.normalizeLayout("scrollingfix"), "scrolling", "legacy Scrolling layout normalizes");
assert.equal(presentation.isSupportedLayout("centerstack", layouts), true, "Lua layout shorthands are supported");
assert.equal(presentation.isSupportedLayout("unknown", layouts), false, "unknown layouts fail closed");

assert.equal(presentation.canOpenAxis(false, "dwindle", false, "horizontal"), false, "unknown status blocks opening");
assert.equal(presentation.canOpenAxis(true, "scrolling", false, "vertical"), false, "Scrolling blocks opening even with an unlocked status flag");
assert.equal(presentation.canOpenAxis(true, "scrollingfix", false, "vertical"), false, "legacy Scrolling blocks opening");
assert.equal(presentation.canOpenAxis(true, "dwindle", true, "horizontal"), false, "reported lock blocks opening");
assert.equal(presentation.canOpenAxis(true, "dwindle", false, "vertical"), true, "a valid unlocked layout permits opening");

const hiddenEntries = presentation.availableMenuEntries(menuEntries.menuEntries, false, true);
assert.equal(hiddenEntries.some(entry => entry.id === "workspace-axis"), false, "the entry stays hidden until menu status validates");
assert.equal(presentation.availableMenuEntries(menuEntries.menuEntries, true, false).some(entry => entry.id === "workspace-axis"), false,
    "the entry is hidden in Scrolling");
assert.equal(presentation.availableMenuEntries(menuEntries.menuEntries, true, true).some(entry => entry.id === "workspace-axis"), true,
    "the entry appears after an unlocked status read");

const pins = ["workspace-axis", "layout", "themes"];
assert.deepEqual(JSON.parse(JSON.stringify(menuEntries.sanitizePinnedIds(pins, availableEntries))), ["layout", "themes"],
    "a hidden pinned entry stays saved while visible pins remain usable");
assert.deepEqual(JSON.parse(JSON.stringify(menuEntries.sanitizePinnedIds(pins))), pins,
    "restoring normal layout visibility restores the saved pin");
assert.equal(menuEntries.filterEntries("workspace axis", availableEntries).some(entry => entry.id === "workspace-axis"), false,
    "search cannot reveal the hidden entry");
assert.equal(presentation.filterAvailableIds(ids, availableIds).includes("workspace-axis"), false,
    "randomized menu choices exclude the hidden entry");
const displayed = menuEntries.chooseDisplayedIds(pins,
    presentation.filterAvailableIds(ids, availableIds), 4, () => 0, false, availableIds);
assert.deepEqual(JSON.parse(JSON.stringify(displayed.slice(0, 2))), ["layout", "themes"],
    "visible saved pins retain their order when one pin is hidden");
assert.equal(displayed.length, 4, "a hidden pin does not reserve a displayed card");
assert.equal(displayed.includes("workspace-axis"), false, "random filler never reveals a hidden entry");

const request = presentation.createOpenRequest(7, 14, "DP-1");
assert.equal(presentation.resolveOpenRequest(request, 7, 14, false, true, false).allowed, false,
    "opening waits for the fresh status result");
assert.equal(presentation.resolveOpenRequest(request, 7, 14, true, false, false).allowed, false,
    "a fresh Scrolling result blocks opening");
assert.equal(presentation.resolveOpenRequest(request, 8, 14, true, true, false).current, false,
    "canceled requests cannot use a stale response");
assert.equal(presentation.resolveOpenRequest(request, 7, 15, true, true, false).current, false,
    "a response cannot open over a different panel");
assert.equal(presentation.resolveOpenRequest(request, 7, 14, true, true, true).allowed, false,
    "another presentation mutation blocks opening");
const allowed = presentation.resolveOpenRequest(request, 7, 14, true, true, false);
assert.equal(allowed.allowed, true, "a valid fresh result opens the panel");
assert.equal(allowed.monitorName, "DP-1", "the initiating monitor survives the asynchronous status read");
assert.equal(presentation.cancelOpenRequest(8).pending, false, "cancel clears pending opening state");

assert.equal(presentation.canStartAction(true, false, "axis", "vertical", layouts), false,
    "a second action cannot replace a pending action");
assert.equal(presentation.canStartAction(false, true, "axis", "vertical", layouts), false,
    "a second action cannot start while the writer is active");
assert.equal(presentation.canStartAction(false, false, "layout", "lua:grid", layouts), true,
    "the current layout menu ID is accepted");
assert.equal(presentation.canStartAction(false, false, "axis", "diagonal", layouts), false,
    "invalid axis values are rejected");
assert.equal(presentation.shouldStartAction(true, "layout", true), false,
    "a refreshed status cannot start a duplicate action while the writer is active");
assert.equal(presentation.shouldStartAction(true, "layout", false), true,
    "a validated pending action starts when the writer is idle");

console.log("PASS: workspace presentation normalization, menu visibility and pins, fresh opening, monitor capture, and action serialization");
