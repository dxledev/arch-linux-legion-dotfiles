#!/usr/bin/env node

"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const services = path.resolve(__dirname, "../../services");
const load = file => fs.readFileSync(path.join(services, file), "utf8").replace(/^\.pragma library\s*/, "");
const dataSource = load("CalendarData.js");
// CalendarEvents.js imports the data tables; evaluate both in one context.
const eventsSource = load("CalendarEvents.js").replace(/^\.import .*\n/, "");
const context = {};
vm.runInNewContext(`${dataSource}\nvar Data = { movableEvents, seasonTimes, meteorShowers };\n${eventsSource}`, context);
const call = expression => vm.runInNewContext(expression, context);
const minutes = (a, b) => Math.abs(a.getTime() - b.getTime()) / 60000;

// USNO moon phase times for Oct-Nov 2026: the algorithm must land within ten minutes.
const phases = [
    [330.75, "2026-10-03T13:25:00Z"], [331, "2026-10-10T15:50:00Z"], [331.25, "2026-10-18T16:12:00Z"],
    [331.5, "2026-10-26T04:12:00Z"], [331.75, "2026-11-01T20:28:00Z"], [332, "2026-11-09T07:02:00Z"],
    [332.25, "2026-11-17T11:48:00Z"], [332.5, "2026-11-24T14:53:00Z"]
];
for (const [k, expected] of phases) {
    const actual = call(`moonPhaseDate(${k})`);
    assert.ok(minutes(actual, new Date(expected)) < 10, `moon phase k=${k}: ${actual.toISOString()} vs ${expected}`);
}

// Every year has 12 or 13 full moons and new moons, and phases alternate in order.
for (let year = 2025; year <= 2032; year++) {
    const list = call(`moonPhases(${year})`);
    for (const name of ["New Moon", "Full Moon"]) {
        const count = list.filter(phase => phase.name === name).length;
        assert.ok(count === 12 || count === 13, `${year} has ${count} ${name}s`);
    }
    const names = ["New Moon", "First Quarter Moon", "Full Moon", "Last Quarter Moon"];
    for (let i = 1; i < list.length; i++) {
        assert.equal(list[i].name, names[(names.indexOf(list[i - 1].name) + 1) % 4], `${year} phases stay in order`);
        assert.ok(list[i].date > list[i - 1].date, `${year} phases stay chronological`);
    }
}

// Movable holidays against known dates (all in UTC-independent date form).
const has = (year, month0, day, title) => call(`eventsFor(${year}, ${month0}, ${day})`).some(event => event.title === title);
assert.ok(has(2026, 1, 17, "Lunar New Year"), "Lunar New Year 2026");
assert.ok(has(2026, 2, 3, "Holi"), "Holi 2026");
assert.ok(has(2026, 10, 8, "Diwali"), "Diwali 2026");
assert.ok(has(2026, 8, 12, "Rosh Hashanah"), "Rosh Hashanah 2026");
assert.ok(has(2026, 11, 4, "Hanukkah begins (evening)"), "Hanukkah 2026");
assert.ok(has(2026, 4, 27, "Eid al-Adha"), "Eid al-Adha 2026");

// Calendar rules.
assert.ok(has(2024, 10, 28, "Thanksgiving"), "Thanksgiving 2024");
assert.ok(has(2024, 2, 31, "Easter Sunday"), "Easter 2024 (Mar 31)");
assert.ok(has(2025, 3, 20, "Easter Sunday"), "Easter 2025 (Apr 20)");
assert.ok(has(2026, 0, 19, "Martin Luther King Jr. Day"), "MLK Day 2026");
assert.ok(has(2026, 5, 21, "Father's Day"), "Father's Day 2026 (Jun 21)");
assert.ok(has(2026, 4, 10, "Mother's Day"), "Mother's Day 2026 (May 10)");

// Table sanity: ISO dates parse, every year has four seasons, kinds are known.
const kinds = new Set(["holiday", "observance", "global", "astro"]);
for (let year = 2025; year <= 2032; year++) {
    assert.equal(call(`Data.seasonTimes[${year}]`).length, 4, `${year} has four season entries`);
    for (const entry of call(`Data.movableEvents[${year}]`)) {
        assert.ok(!Number.isNaN(new Date(entry[0].length > 10 ? entry[0] : entry[0] + "T00:00:00Z").getTime()), `valid date ${entry[0]}`);
        assert.ok(kinds.has(entry[2]), `known kind ${entry[2]}`);
    }
}
console.log("PASS: calendar events, moon phases and tables");
