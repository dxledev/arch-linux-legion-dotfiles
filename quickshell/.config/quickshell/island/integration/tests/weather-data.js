#!/usr/bin/env node

"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const source = fs.readFileSync(path.resolve(__dirname, "../../services/WeatherData.js"), "utf8").replace(/^\.pragma library\s*/, "");
const context = {};
vm.createContext(context);
vm.runInContext(source + "\nthis.W = { forecastDays, condition, iconName, parse, placeNow, findDay, isNight, toUnits, formatTemp, formatWind, formatPercent, formatHour, formatClock, parseCoords, parseIpLocation, parseGeocode, forecastUrl, hourRange };", context);
const W = context.W;

// A two-day Open-Meteo body, trimmed to the fields the panel reads.
function body(overrides = {}) {
    const hours = [];
    for (const date of ["2026-10-15", "2026-10-16"])
        for (let hour = 0; hour < 24; hour++) hours.push([`${date}T${String(hour).padStart(2, "0")}:00`, 10 + hour / 2, 8 + hour / 2, hour * 4 % 100, hour < 12 ? 3 : 61]);
    return JSON.stringify(Object.assign({
        utc_offset_seconds: -14400,
        hourly: {
            time: hours.map(h => h[0]), temperature_2m: hours.map(h => h[1]), apparent_temperature: hours.map(h => h[2]),
            precipitation_probability: hours.map(h => h[3]), weather_code: hours.map(h => h[4])
        },
        daily: {
            time: ["2026-10-15", "2026-10-16"], weather_code: [3, 61], temperature_2m_max: [21.5, 18], temperature_2m_min: [10, 9.4],
            sunrise: ["2026-10-15T07:12", "2026-10-16T07:13"], sunset: ["2026-10-15T18:04", "2026-10-16T18:02"],
            precipitation_probability_max: [20, 85], wind_speed_10m_max: [16.1, 30]
        }
    }, overrides));
}

const forecast = W.parse(body());
assert.equal(forecast.days.length, 2);
assert.equal(forecast.utcOffsetSeconds, -14400);
assert.equal(forecast.days[0].hours.length, 24, "Hours group under their own day");
assert.equal(forecast.days[1].hours[13].code, 61);
assert.equal(forecast.days[0].sunrise, "07:12");
assert.equal(W.findDay(forecast, "2026-10-16").hiC, 18);
assert.equal(W.findDay(forecast, "2026-11-01"), null);

// Bad bodies never produce a forecast.
assert.throws(() => W.parse("not json"));
assert.throws(() => W.parse("{}"));
assert.throws(() => W.parse(JSON.stringify({ hourly: { time: [] }, daily: { time: [] } })), /no days/);
const partial = W.parse(body({ daily: { time: ["2026-10-15", "2026-10-16"], temperature_2m_max: [20, null], temperature_2m_min: [10, 9] } }));
assert.equal(partial.days.length, 1, "A day without temperatures is dropped");

// Units and formatting.
assert.equal(W.toUnits(21.5, "Fahrenheit"), 71);
assert.equal(W.toUnits(21.5, "fahrenheit"), 71, "Unit names are case-insensitive");
assert.equal(W.toUnits(21.5, "Celsius"), 22);
assert.equal(W.formatTemp(-0.4, "Celsius"), "0°");
assert.equal(W.formatTemp(undefined, "Celsius"), "--");
assert.equal(W.formatWind(16.1, "Fahrenheit"), "10 mph");
assert.equal(W.formatWind(16.1, "Celsius"), "16 km/h");
assert.equal(W.formatPercent(84.6), "85%");
assert.equal(W.formatHour(0, true), "12a");
assert.equal(W.formatHour(15, true), "3p");
assert.equal(W.formatHour(5, false), "05");
assert.equal(W.formatClock("07:12", true), "7:12 AM");
assert.equal(W.formatClock("18:04", true), "6:04 PM");
assert.equal(W.formatClock("00:30", true), "12:30 AM");
assert.equal(W.formatClock("18:04", false), "18:04");
assert.equal(W.formatClock("", true), "--");

// Codes map to words and icons; clear skies turn into the moon at night.
assert.equal(W.condition(63), "Rain");
assert.equal(W.condition(1234), "Unknown");
assert.equal(W.iconName(0, false), "weather-sun");
assert.equal(W.iconName(0, true), "moon");
assert.equal(W.iconName(2, false), "weather-cloud-sun");
assert.equal(W.iconName(45, false), "weather-cloud-fog");
assert.equal(W.iconName(55, false), "weather-cloud-drizzle");
assert.equal(W.iconName(82, false), "weather-cloud-rain");
assert.equal(W.iconName(75, false), "weather-cloud-snow");
assert.equal(W.iconName(99, false), "weather-cloud-storm");

// The forecast's own clock, not the machine's: 2026-10-16 02:30 UTC is still the 15th at UTC-4.
const now = W.placeNow(-14400, Date.UTC(2026, 9, 16, 2, 30));
assert.deepEqual({ key: now.key, hour: now.hour }, { key: "2026-10-15", hour: 22 });
assert.equal(W.isNight(forecast.days[0], 22), true);
assert.equal(W.isNight(forecast.days[0], 12), false);
assert.equal(W.isNight(forecast.days[0], 6), true);

// Locations: coordinates, ip-api and the geocoder.
assert.deepEqual({ ...W.parseCoords("40.7, -74") }, { lat: 40.7, lon: -74 });
assert.equal(W.parseCoords("Boston"), null);
assert.equal(W.parseCoords("Paris, France"), null);
assert.equal(W.parseCoords("95,10"), null, "Latitude out of range is a name, not coordinates");
assert.equal(W.parseCoords(",5"), null);
assert.deepEqual({ ...W.parseIpLocation('{"status":"success","city":"Boston","lat":42.36,"lon":-71.06}') }, { lat: 42.36, lon: -71.06, city: "Boston" });
assert.throws(() => W.parseIpLocation('{"status":"fail","message":"private range"}'), /private range/);
assert.deepEqual({ ...W.parseGeocode('{"results":[{"name":"Lyon","latitude":45.75,"longitude":4.85}]}') }, { lat: 45.75, lon: 4.85, city: "Lyon" });
assert.throws(() => W.parseGeocode('{"generationtime_ms":0.4}'), /No place/);
const url = W.forecastUrl("https://api.open-meteo.com/v1/forecast", { lat: 1.5, lon: -2 });
assert.ok(url.includes("latitude=1.5&longitude=-2") && url.includes("forecast_days=" + W.forecastDays) && url.includes("timezone=auto"));
assert.equal(W.forecastDays, 15);

// Curve range never collapses, even on a flat day.
assert.deepEqual({ ...W.hourRange([{ tempC: 10 }, { tempC: 10 }]) }, { lo: 8, hi: 12 });
assert.deepEqual({ ...W.hourRange([{ tempC: 3 }, { tempC: 15 }]) }, { lo: 3, hi: 15 });
assert.deepEqual({ ...W.hourRange([]) }, { lo: 0, hi: 1 });

console.log("PASS: weather data parsing, units and locations");
