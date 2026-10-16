#!/usr/bin/env node

"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const islandRoot = path.resolve(__dirname, "../..");
const sourcePath = path.join(islandRoot, "services/TimerLogic.js");
const logic = {};
vm.runInNewContext(fs.readFileSync(sourcePath, "utf8").replace(/^\.pragma library\s*/, ""), logic, { filename: sourcePath });
const plain = value => JSON.parse(JSON.stringify(value));

// Digits fill from the right, like a microwave.
const typed = digits => [...digits].reduce((text, digit) => logic.appendDigit(text, digit), "");
const typedSeconds = digits => logic.digitsToSeconds(typed(digits));
assert.equal(typedSeconds("1500"), 15 * 60, "1 5 0 0 is fifteen minutes");
assert.equal(typedSeconds("5"), 5, "one digit is seconds");
assert.equal(typedSeconds("90"), 90, "seconds past 59 carry into minutes");
assert.equal(typedSeconds("13000"), 90 * 60, "1:30:00");
assert.equal(typed("0005"), "5", "leading zeros are not kept");
assert.equal(typed("0"), "", "a lone zero is still nothing");
assert.equal(typed("99"), "99", "what was typed stays as typed");
assert.equal(typedSeconds("999"), 9 * 60 + 99, "9:99 is 10:39");
assert.equal(typed("1234567"), "123456", "a seventh digit is ignored");
assert.equal(typedSeconds("999999"), logic.maximumSeconds, "the longest timer is 99:59:59");
assert.equal(logic.appendDigit("12", "x"), "12", "a non-digit changes nothing");
assert.equal(logic.removeDigit("1500"), "150", "backspace drops the last digit");
assert.equal(logic.removeDigit("5"), "", "backspace on one digit clears");
assert.equal(logic.removeDigit(""), "", "backspace on nothing stays empty");
assert.equal(logic.digitsToSeconds(""), 0);
assert.equal(logic.secondsToDigits(5400), "13000");
assert.equal(logic.secondsToDigits(0), "");
assert.equal(logic.digitsToSeconds(logic.secondsToDigits(4321)), 4321, "dial and presets round-trip through digits");
assert.equal(logic.addMinutes(30, 5), 330, "a preset adds to the dialed time");
assert.equal(logic.addMinutes(logic.maximumSeconds, 5), logic.maximumSeconds, "presets stop at the longest timer");
assert.equal(logic.clampSeconds(-4), 0);
assert.equal(logic.clampSeconds("abc"), 0);
assert.equal(logic.clampSeconds(1e12), logic.maximumSeconds);

// Formatting.
assert.equal(logic.formatClock(0), "00:00");
assert.equal(logic.formatClock(65), "01:05");
assert.equal(logic.formatClock(3599), "59:59");
assert.equal(logic.formatClock(3600), "1:00:00");
assert.equal(logic.formatClock(5400 + 7), "1:30:07");
assert.equal(logic.formatRemaining(1), "00:01", "the last second reads 00:01 until it ends");
assert.equal(logic.formatRemaining(1000), "00:01");
assert.equal(logic.formatRemaining(1001), "00:02");
assert.equal(logic.formatRemaining(-50), "00:00");
assert.equal(logic.formatRemaining(NaN), "00:00");
assert.equal(logic.describe(300), "5 min");
assert.equal(logic.describe(5400), "1 h 30 min");
assert.equal(logic.describe(90), "1 min 30 s");
assert.equal(logic.describe(45), "45 s");
assert.equal(logic.describe(3605), "1 h 5 s");
assert.equal(logic.describe(0), "0 s");

// The dial: angles run clockwise from 12 o'clock, one full turn is an hour.
assert.equal(logic.angleAt(0, -10), 0, "straight up");
assert.equal(logic.angleAt(10, 0), 90, "right");
assert.equal(logic.angleAt(0, 10), 180, "down");
assert.equal(logic.angleAt(-10, 0), 270, "left");
assert.equal(logic.dialMinutesAt(0), 0);
assert.equal(logic.dialMinutesAt(90), 15);
assert.equal(logic.dialMinutesAt(180), 30);
assert.equal(logic.dialMinutesAt(271), 45);
assert.equal(logic.dialMinutesAt(359.9), 60, "just left of 12 o'clock is a full hour without a drag");
assert.equal(logic.dialMinutesAt(-90), 45, "negative angles wrap");
assert.equal(logic.dialMinutesAt(3), 1, "6 degrees is one minute");
assert.equal(logic.dialMinutesAt(5, 58), 60, "dragging clockwise past 12 reaches the full hour");
assert.equal(logic.dialMinutesAt(355, 3), 0, "dragging back past 12 reaches zero");
assert.equal(logic.dialMinutesAt(5, 30), 1, "a jump to the top from the far side is not a drag");
assert.equal(logic.dialMinutesAt(180, 90), 30, "a typed duration over an hour clamps before it is compared");
assert.equal(logic.dialFill(0), 0);
assert.equal(logic.dialFill(1800), 0.5);
assert.equal(logic.dialFill(7200), 1, "an hour or more is the whole ring");

// Timers.
const now = 1_000_000;
const tea = logic.createTimer("a", "  Tea \n  time ", 300, true, now);
assert.deepEqual(plain(tea), { id: "a", label: "Tea time", durationMs: 300000, startedAt: now, endsAt: now + 300000, indefinite: true, sound: "", snooze: 0, snoozed: false, originalMs: 300000, paused: false, pausedMs: 0 });
assert.equal(logic.createTimer("s", "", 60, false, now, "bell").sound, "bell", "a timer carries its sound");
assert.equal(logic.createTimer("s", "", 60, false, now, "../../etc/passwd").sound, "", "only known sounds are kept");
assert.equal(logic.createTimer("s", "", 60, false, now, undefined).sound, "", "no sound unless asked");
assert.equal(logic.createTimer("b", undefined, 60, undefined, now).indefinite, false, "alerts expire unless asked otherwise");
assert.equal(logic.createTimer("b", "x".repeat(200), 60, false, now).label.length, logic.maximumLabelLength);
assert.equal(logic.remainingMs(tea, now + 100000), 200000);
assert.equal(logic.remainingMs(tea, now + 999999), 0);
assert.equal(logic.progress(tea, now), 1);
assert.equal(logic.progress(tea, now + 150000), 0.5);
assert.equal(logic.progress(tea, now + 400000), 0);
assert.equal(logic.progress(null, now), 0);
assert.ok(!logic.isUrgent(tea, now) && logic.isUrgent(tea, now + 295000) && logic.isUrgent(tea, now + 300000));
assert.notEqual(logic.makeId(now, 1), logic.makeId(now, 2));

const later = logic.createTimer("c", "Laundry", 3600, false, now), soon = logic.createTimer("d", "", 30, false, now);
const split = logic.partition([later, tea, soon], now + 31000);
assert.deepEqual(plain(split.running.map(timer => timer.id)), ["a", "c"], "running timers sort by what ends first");
assert.deepEqual(plain(split.due.map(timer => timer.id)), ["d"]);
assert.deepEqual(plain(logic.partition([soon], now + 30000).due.map(timer => timer.id)), ["d"], "a timer is due the moment it ends");
assert.deepEqual(plain(logic.sortTimers([later, soon, tea]).map(timer => timer.id)), ["d", "a", "c"]);

// The saved file.
const empty = { timers: [], keepAlert: false, soundEnabled: false, soundName: "alarm-clock-elapsed", snoozeEnabled: false, snoozeSeconds: 300 };
const saved = logic.serialize([later, tea], { keepAlert: true, soundEnabled: true, soundName: "bell" });
const restored = plain(logic.parseStored(saved));
assert.equal(restored.keepAlert, true);
assert.ok(restored.soundEnabled && restored.soundName === "bell", "the sound choice is kept");
assert.equal(plain(logic.parseStored(logic.serialize([logic.createTimer("q", "", 60, false, now, "complete")], {}))).timers[0].sound, "complete", "a timer's sound is kept");
assert.deepEqual(plain(logic.parseStored(logic.serialize([], undefined))), empty, "no preferences means the defaults");
assert.deepEqual(restored.timers.map(timer => timer.id), ["a", "c"]);
assert.deepEqual(plain(logic.parseStored("")), empty);
assert.deepEqual(plain(logic.parseStored("not json")), empty);
assert.deepEqual(plain(logic.parseStored("[1,2]")), empty);
const damaged = plain(logic.parseStored(JSON.stringify({ version: 1, keepAlert: "yes", timers: [
    tea, tea, { id: "", durationMs: 1, startedAt: 1, endsAt: 2 }, { id: "z", durationMs: -5, startedAt: 1, endsAt: 2 },
    { id: "y", durationMs: 5, startedAt: "x", endsAt: 2 }, null, "x", { id: "w", label: 7, durationMs: 5000, startedAt: 1, endsAt: 5001 }
] })));
assert.equal(damaged.keepAlert, false, "only a real true keeps alerts");
assert.ok(!damaged.soundEnabled && damaged.soundName === "alarm-clock-elapsed", "missing sound settings fall back");
const odd = plain(logic.parseStored(JSON.stringify({ soundEnabled: "yes", soundName: "../x", timers: [{ ...tea, sound: "nope" }] })));
assert.ok(!odd.soundEnabled && odd.soundName === "alarm-clock-elapsed" && odd.timers[0].sound === "", "unknown sounds never come back from the file");
assert.deepEqual(damaged.timers.map(timer => timer.id), ["w", "a"], "duplicates and malformed timers are dropped, the rest kept in order");
assert.equal(damaged.timers[0].label, "7");
const many = Array.from({ length: 50 }, (_, index) => logic.createTimer("t" + index, "", 60, false, now + index));
assert.equal(logic.parseStored(logic.serialize(many, false)).timers.length, logic.maximumTimers, "a damaged file cannot flood the island");

// Sounds.
assert.ok(logic.sounds.length >= 4 && logic.sounds.every(sound => /^[a-z0-9-]+$/.test(sound.key) && sound.label), "every sound is a plain file name with a label");
assert.equal(new Set(logic.sounds.map(sound => sound.key)).size, logic.sounds.length, "no sound is listed twice");
assert.ok(logic.knownSound("bell") && !logic.knownSound("") && !logic.knownSound("../bell") && !logic.knownSound(undefined));
assert.equal(logic.soundOrDefault("bell"), "bell");
assert.equal(logic.soundOrDefault("nope"), logic.defaultSound);
assert.equal(logic.soundFile("/usr/share/sounds/freedesktop/stereo/", "bell"), "/usr/share/sounds/freedesktop/stereo/bell.oga");
assert.equal(logic.soundFile("/x", "complete"), "/x/complete.oga");

// Snoozing.
assert.equal(logic.createTimer("s", "", 60, false, now, "bell", 120).snooze, 120, "a timer carries its snooze length");
assert.equal(logic.createTimer("s", "", 60, false, now, "bell", 0).snooze, 0, "no snooze unless asked");
assert.equal(logic.createTimer("s", "", 60, false, now, "bell", 99999).snooze, logic.maximumSnooze, "a snooze is at most an hour");
assert.equal(logic.clampSnooze("x"), logic.defaultSnooze);
assert.equal(logic.clampSnooze(2), 2);
assert.ok(logic.snoozeChoices.every(seconds => seconds > 0 && seconds <= logic.maximumSnooze) && logic.snoozeChoices.includes(logic.defaultSnooze));
const nap = logic.createTimer("n", "Tea", 600, true, now, "bell", 120);
const again = logic.snoozeTimer(nap, "n2", now + 600000);
assert.deepEqual(plain(again), { id: "n2", label: "Tea", durationMs: 120000, startedAt: now + 600000, endsAt: now + 720000, indefinite: true, sound: "bell", snooze: 120, snoozed: true, originalMs: 600000, paused: false, pausedMs: 0 });
assert.equal(logic.snoozeTimer(again, "n3", now).originalMs, 600000, "snoozing again still remembers the first timer");
assert.deepEqual(plain(logic.alertActions(nap)), [{ key: "stop", text: "Stop" }, { key: "snooze", text: "Snooze" }]);
assert.deepEqual(plain(logic.alertActions(logic.createTimer("q", "", 60, false, now, "bell", 0))), [{ key: "stop", text: "Stop" }], "no snooze button unless the timer allows it");
assert.deepEqual(plain(logic.alertActions(logic.createTimer("q", "", 60, false, now, "", 60))), [{ key: "snooze", text: "Snooze" }], "no stop button without a sound");
assert.deepEqual(plain(logic.alertActions(tea)), [], "a plain alert has no buttons");
const kept = plain(logic.parseStored(logic.serialize([again], { snoozeEnabled: true, snoozeSeconds: 600 })));
assert.ok(kept.snoozeEnabled && kept.snoozeSeconds === 600, "the snooze choice is kept");
assert.deepEqual(kept.timers[0], plain(again), "a snoozed timer survives the file");
const old = plain(logic.parseStored(JSON.stringify({ timers: [{ id: "o", durationMs: 5000, startedAt: 1, endsAt: 5001 }] })));
assert.ok(old.timers[0].snooze === 0 && !old.timers[0].snoozed && old.timers[0].originalMs === 5000, "a file from before snoozing still loads");
assert.ok(!old.snoozeEnabled && old.snoozeSeconds === 300);

// Pausing.
const run = logic.createTimer("p", "Run", 600, false, now), other = logic.createTimer("o", "Other", 900, false, now);
const held = logic.pauseTimer(run, now + 100000);
assert.ok(held.paused && held.pausedMs === 500000 && run.paused === false, "pausing keeps what was left and leaves the original alone");
assert.equal(logic.remainingMs(held, now + 9e9), 500000, "a paused timer's time stands still");
assert.equal(logic.progress(held, now + 9e9), 500000 / 600000);
assert.equal(logic.pauseTimer(held, now + 200000), held, "pausing twice changes nothing");
assert.deepEqual(plain(logic.partition([held], now + 9e9).due), [], "a paused timer never goes off");
assert.deepEqual(plain(logic.sortTimers([held, other]).map(timer => timer.id)), ["o", "p"], "paused timers come after running ones");
const resumed = logic.resumeTimer(held, now + 300000);
assert.ok(!resumed.paused && resumed.pausedMs === 0 && resumed.endsAt === now + 800000, "resuming counts the rest down from then");
assert.equal(logic.resumeTimer(run, now), run, "resuming a running timer changes nothing");
const reloaded = plain(logic.parseStored(logic.serialize([held, other], {})));
assert.ok(reloaded.timers.find(timer => timer.id === "p").paused && reloaded.timers.find(timer => timer.id === "p").pausedMs === 500000, "a paused timer survives the file");
assert.ok(!plain(logic.parseStored(JSON.stringify({ timers: [{ ...plain(run), paused: true, pausedMs: 0 }] }))).timers[0].paused, "a pause with nothing left is dropped");

// Alert text.
assert.deepEqual(plain(logic.alertText(tea, 0, "")), { summary: "Tea time", body: "Your 5 min timer is up." });
assert.deepEqual(plain(logic.alertText(soon, 500, "14:32")), { summary: "Timer finished", body: "Your 30 s timer is up." });
assert.equal(logic.alertText(tea, 600000, "14:32").body, "Your 5 min timer is up. It ended at 14:32.", "a timer noticed late says when it ended");
assert.equal(logic.alertText(tea, 600000, "").body, "Your 5 min timer is up.");

assert.equal(logic.alertText(again, 0, "").body, "Your 10 min timer is up again.", "a snoozed timer names the timer it came from");

console.log("PASS: timer digit entry, dial, formatting, saved file, sounds and alert text");
