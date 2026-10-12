#!/usr/bin/env node
"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const selectionPath = path.resolve(__dirname, "../../services/MediaSelection.js");
const selection = {};
vm.runInNewContext(fs.readFileSync(selectionPath, "utf8").replace(/^\.pragma library\s*/, ""), selection);

const paused = {playbackState: 2};
const playing = {playbackState: 1};
const anotherPlaying = {playbackState: 1};

assert.equal(selection.selectPlayer([paused, playing], paused, 1), playing,
    "The playing player takes priority over the first paused player");
assert.equal(selection.selectPlayer([anotherPlaying, playing], playing, 1), playing,
    "Concurrent players do not steal selection from the current playing player");
playing.playbackState = 2;
assert.equal(selection.selectPlayer([paused, playing], playing, 1), playing,
    "Pausing retains the selected player so the next toggle resumes it");
assert.equal(selection.selectPlayer([paused, anotherPlaying], playing, 1), anotherPlaying,
    "A removed player is replaced by a player that is currently playing");
assert.equal(selection.selectPlayer([paused], playing, 1), paused,
    "The remaining paused player is available when the selected player disappears");
assert.equal(selection.selectPlayer([], playing, 1), null, "No players clears selection");

console.log("PASS: playing media selection, stable pause/resume, concurrent players and removal");
