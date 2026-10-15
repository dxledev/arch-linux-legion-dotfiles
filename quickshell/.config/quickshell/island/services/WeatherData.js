.pragma library

// Pure helpers for the Forecast panel: Open-Meteo and ip-api response parsing, WMO weather codes and
// unit formatting. WeatherService does the fetching and caching; nothing here touches the network.

// Open-Meteo offers 16, but the last one arrives without temperatures, so ask for the 15 that are complete.
var forecastDays = 15

var conditions = {
    0: "Clear", 1: "Mostly clear", 2: "Partly cloudy", 3: "Overcast",
    45: "Fog", 48: "Freezing fog",
    51: "Light drizzle", 53: "Drizzle", 55: "Heavy drizzle", 56: "Freezing drizzle", 57: "Freezing drizzle",
    61: "Light rain", 63: "Rain", 65: "Heavy rain", 66: "Freezing rain", 67: "Freezing rain",
    71: "Light snow", 73: "Snow", 75: "Heavy snow", 77: "Snow grains",
    80: "Light showers", 81: "Showers", 82: "Heavy showers", 85: "Snow showers", 86: "Heavy snow showers",
    95: "Thunderstorm", 96: "Thunderstorm with hail", 99: "Thunderstorm with hail"
}

function condition(code) {
    return conditions[code] || "Unknown"
}

// Icon file under assets/icons. Clear skies switch to the moon after dark.
function iconName(code, night) {
    if (code === 0 || code === 1) return night ? "moon" : "weather-sun"
    if (code === 2) return night ? "weather-cloud" : "weather-cloud-sun"
    if (code === 3) return "weather-cloud"
    if (code === 45 || code === 48) return "weather-cloud-fog"
    if (code >= 51 && code <= 57) return "weather-cloud-drizzle"
    if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) return "weather-cloud-rain"
    if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "weather-cloud-snow"
    if (code >= 95) return "weather-cloud-storm"
    return "weather-cloud"
}

function isNumber(value) {
    return typeof value === "number" && isFinite(value)
}

function number(value, fallback) {
    return isNumber(value) ? value : fallback
}

// "2026-10-15T06:52" -> "06:52"
function clockOf(stamp) {
    return typeof stamp === "string" && stamp.length >= 16 ? stamp.slice(11, 16) : ""
}

// Open-Meteo forecast JSON -> { utcOffsetSeconds, days: [{ key, hiC, loC, code, precip, windKmh,
// sunrise, sunset, hours: [24 x { hour, tempC, feelsC, precip, code }] }] }. Throws on a body that
// is not a forecast, so a bad response never replaces good data.
function parse(text) {
    var json = JSON.parse(text)
    if (!json || !json.daily || !json.hourly || !Array.isArray(json.daily.time) || !Array.isArray(json.hourly.time))
        throw new Error("Not a forecast response")
    var daily = json.daily
    var hourly = json.hourly
    var byDay = {}
    for (var i = 0; i < hourly.time.length; i++) {
        var stamp = String(hourly.time[i])
        var key = stamp.slice(0, 10)
        if (!byDay[key]) byDay[key] = []
        var temp = hourly.temperature_2m ? hourly.temperature_2m[i] : null
        if (!isNumber(temp)) continue
        byDay[key].push({
            hour: Number(stamp.slice(11, 13)),
            tempC: temp,
            feelsC: number(hourly.apparent_temperature && hourly.apparent_temperature[i], temp),
            precip: number(hourly.precipitation_probability && hourly.precipitation_probability[i], 0),
            code: number(hourly.weather_code && hourly.weather_code[i], 0)
        })
    }
    var days = []
    for (var d = 0; d < daily.time.length; d++) {
        var dayKey = String(daily.time[d])
        var hi = daily.temperature_2m_max ? daily.temperature_2m_max[d] : null
        var lo = daily.temperature_2m_min ? daily.temperature_2m_min[d] : null
        if (!isNumber(hi) || !isNumber(lo)) continue
        days.push({
            key: dayKey,
            hiC: hi,
            loC: lo,
            code: number(daily.weather_code && daily.weather_code[d], 0),
            precip: number(daily.precipitation_probability_max && daily.precipitation_probability_max[d], 0),
            windKmh: number(daily.wind_speed_10m_max && daily.wind_speed_10m_max[d], 0),
            sunrise: clockOf(daily.sunrise && daily.sunrise[d]),
            sunset: clockOf(daily.sunset && daily.sunset[d]),
            hours: byDay[dayKey] || []
        })
    }
    if (days.length === 0) throw new Error("Forecast has no days")
    return { utcOffsetSeconds: number(json.utc_offset_seconds, 0), days: days }
}

// The forecast's own "now": the date key and hour at the forecast location, not on this machine.
function placeNow(utcOffsetSeconds, nowMs) {
    var shifted = new Date(nowMs + utcOffsetSeconds * 1000)
    var pad = function (n) { return (n < 10 ? "0" : "") + n }
    return {
        key: shifted.getUTCFullYear() + "-" + pad(shifted.getUTCMonth() + 1) + "-" + pad(shifted.getUTCDate()),
        hour: shifted.getUTCHours()
    }
}

function findDay(forecast, key) {
    if (!forecast) return null
    for (var i = 0; i < forecast.days.length; i++)
        if (forecast.days[i].key === key) return forecast.days[i]
    return null
}

function isNight(day, hour) {
    if (!day || !day.sunrise || !day.sunset) return hour < 6 || hour >= 20
    var rise = Number(day.sunrise.slice(0, 2)) + Number(day.sunrise.slice(3, 5)) / 60
    var set = Number(day.sunset.slice(0, 2)) + Number(day.sunset.slice(3, 5)) / 60
    return hour + 0.5 < rise || hour + 0.5 > set
}

function fahrenheit(units) {
    return String(units).toLowerCase() === "fahrenheit"
}

function toUnits(celsius, units) {
    return Math.round(fahrenheit(units) ? celsius * 9 / 5 + 32 : celsius)
}

function formatTemp(celsius, units) {
    if (!isNumber(celsius)) return "--"
    return toUnits(celsius, units) + "°"
}

function formatWind(kmh, units) {
    if (!isNumber(kmh)) return "--"
    return fahrenheit(units) ? Math.round(kmh * 0.621371) + " mph" : Math.round(kmh) + " km/h"
}

function formatPercent(value) {
    return isNumber(value) ? Math.round(value) + "%" : "--"
}

function formatHour(hour, twelveHour) {
    if (!twelveHour) return (hour < 10 ? "0" : "") + hour
    var suffix = hour < 12 ? "a" : "p"
    return (hour % 12 === 0 ? 12 : hour % 12) + suffix
}

// "07:12" -> "7:12 AM" or unchanged on a 24-hour clock.
function formatClock(clock, twelveHour) {
    if (!clock) return "--"
    if (!twelveHour) return clock
    var hour = Number(clock.slice(0, 2))
    return (hour % 12 === 0 ? 12 : hour % 12) + ":" + clock.slice(3, 5) + (hour < 12 ? " AM" : " PM")
}

// "40.7,-74" -> { lat, lon }, or null when the text is a place name.
function parseCoords(text) {
    var parts = String(text || "").split(",")
    if (parts.length !== 2) return null
    var lat = Number(parts[0].trim())
    var lon = Number(parts[1].trim())
    if (parts[0].trim() === "" || parts[1].trim() === "" || !isFinite(lat) || !isFinite(lon)
        || Math.abs(lat) > 90 || Math.abs(lon) > 180) return null
    return { lat: lat, lon: lon }
}

// ip-api.com reply -> { lat, lon, city }.
function parseIpLocation(text) {
    var json = JSON.parse(text)
    var lat = Number(json.lat)
    var lon = Number(json.lon)
    if (json.status !== "success" || !isFinite(lat) || !isFinite(lon))
        throw new Error(json.message || "Location lookup failed")
    return { lat: lat, lon: lon, city: String(json.city || "") }
}

// Open-Meteo geocoding reply -> { lat, lon, city } for the first match.
function parseGeocode(text) {
    var json = JSON.parse(text)
    var hit = json.results && json.results[0]
    if (!hit || !isFinite(Number(hit.latitude)) || !isFinite(Number(hit.longitude)))
        throw new Error("No place found")
    return { lat: Number(hit.latitude), lon: Number(hit.longitude), city: String(hit.name || "") }
}

function forecastUrl(base, place) {
    return base + "?latitude=" + place.lat + "&longitude=" + place.lon
        + "&hourly=weather_code,temperature_2m,apparent_temperature,precipitation_probability"
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max,wind_speed_10m_max"
        + "&timezone=auto&forecast_days=" + forecastDays
}

// Lowest and highest hourly temperature of a day, padded so the curve never touches the edges.
function hourRange(hours) {
    var lo = Infinity
    var hi = -Infinity
    for (var i = 0; i < hours.length; i++) {
        lo = Math.min(lo, hours[i].tempC)
        hi = Math.max(hi, hours[i].tempC)
    }
    if (!isFinite(lo)) return { lo: 0, hi: 1 }
    if (hi - lo < 4) { var mid = (hi + lo) / 2; lo = mid - 2; hi = mid + 2 }
    return { lo: lo, hi: hi }
}
