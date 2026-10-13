.pragma library
.import "CalendarData.js" as Data

// Holidays and global events for the Calendar panel, computed offline. Rules cover US federal
// holidays, common observances, international days, DST changes, moon phases and meteor showers.
// Dates that cannot be computed (lunar and religious calendars, eclipses, solstices) come from
// the tables in CalendarData.js. Kinds, most to least prominent: holiday, observance, global, astro.


var kindOrder = { holiday: 0, observance: 1, global: 2, astro: 3 }
var cache = {}

function pad2(n) { return (n < 10 ? "0" : "") + n }
function key(month0, day) { return pad2(month0 + 1) + "-" + pad2(day) }

// The nth (1-based) weekday (0 = Sunday) of a month.
function nthWeekday(year, month0, weekday, n) {
    var first = new Date(year, month0, 1).getDay()
    return 1 + ((weekday - first + 7) % 7) + (n - 1) * 7
}

function lastWeekday(year, month0, weekday) {
    var last = new Date(year, month0 + 1, 0)
    return last.getDate() - ((last.getDay() - weekday + 7) % 7)
}

// Anonymous Gregorian algorithm.
function easter(year) {
    var a = year % 19, b = Math.floor(year / 100), c = year % 100
    var d = Math.floor(b / 4), e = b % 4, f = Math.floor((b + 8) / 25)
    var g = Math.floor((b - f + 1) / 3)
    var h = (19 * a + b - d - g + 15) % 30
    var i = Math.floor(c / 4), k = c % 4
    var l = (32 + 2 * e + 2 * i - h - k) % 7
    var m = Math.floor((a + 11 * h + 22 * l) / 451)
    var month = Math.floor((h + l - 7 * m + 114) / 31)
    var day = ((h + l - 7 * m + 114) % 31) + 1
    return new Date(year, month - 1, day)
}

// ---- Moon phases (Meeus, Astronomical Algorithms ch. 49, main periodic terms) ----

var rad = Math.PI / 180

function moonPhaseDate(k) {
    var T = k / 1236.85, T2 = T * T, T3 = T2 * T, T4 = T3 * T
    var jde = 2451550.09766 + 29.530588861 * k + 0.00015437 * T2 - 0.00000015 * T3 + 0.00000000073 * T4
    var E = 1 - 0.002516 * T - 0.0000074 * T2
    var M = (2.5534 + 29.10535670 * k - 0.0000014 * T2 - 0.00000011 * T3) * rad
    var Mp = (201.5643 + 385.81693528 * k + 0.0107582 * T2 + 0.00001238 * T3 - 0.000000058 * T4) * rad
    var F = (160.7108 + 390.67050284 * k - 0.0016118 * T2 - 0.00000227 * T3 + 0.000000011 * T4) * rad
    var O = (124.7746 - 1.56375588 * k + 0.0020672 * T2 + 0.00000215 * T3) * rad
    var phase = Math.round((k - Math.floor(k)) * 4) % 4
    var s = Math.sin, c = Math.cos, corr
    if (phase === 0) {
        corr = -0.40720 * s(Mp) + 0.17241 * E * s(M) + 0.01608 * s(2 * Mp) + 0.01039 * s(2 * F)
            + 0.00739 * E * s(Mp - M) - 0.00514 * E * s(Mp + M) + 0.00208 * E * E * s(2 * M)
            - 0.00111 * s(Mp - 2 * F) - 0.00057 * s(Mp + 2 * F) + 0.00056 * E * s(2 * Mp + M)
            - 0.00042 * s(3 * Mp) + 0.00042 * E * s(M + 2 * F) + 0.00038 * E * s(M - 2 * F)
            - 0.00024 * E * s(2 * Mp - M) - 0.00017 * s(O)
    } else if (phase === 2) {
        corr = -0.40614 * s(Mp) + 0.17302 * E * s(M) + 0.01614 * s(2 * Mp) + 0.01043 * s(2 * F)
            + 0.00734 * E * s(Mp - M) - 0.00515 * E * s(Mp + M) + 0.00209 * E * E * s(2 * M)
            - 0.00111 * s(Mp - 2 * F) - 0.00057 * s(Mp + 2 * F) + 0.00056 * E * s(2 * Mp + M)
            - 0.00042 * s(3 * Mp) + 0.00042 * E * s(M + 2 * F) + 0.00038 * E * s(M - 2 * F)
            - 0.00024 * E * s(2 * Mp - M) - 0.00017 * s(O)
    } else {
        corr = -0.62801 * s(Mp) + 0.17172 * E * s(M) - 0.01183 * E * s(Mp + M) + 0.00862 * s(2 * Mp)
            + 0.00804 * s(2 * F) + 0.00454 * E * s(Mp - M) + 0.00204 * E * E * s(2 * M)
            - 0.00180 * s(Mp - 2 * F) - 0.00070 * s(Mp + 2 * F) - 0.00040 * s(3 * Mp)
            - 0.00034 * E * s(2 * Mp - M) + 0.00032 * E * s(M + 2 * F) + 0.00032 * E * s(M - 2 * F)
            - 0.00028 * E * E * s(Mp + 2 * M) + 0.00027 * E * s(2 * Mp + M) - 0.00017 * s(O)
        var W = 0.00306 - 0.00038 * E * c(M) + 0.00026 * c(Mp) - 0.00002 * c(Mp - M)
            + 0.00002 * c(Mp + M) + 0.00002 * c(2 * F)
        corr += phase === 1 ? W : -W
    }
    return new Date((jde + corr - 2440587.5) * 86400000)
}

var moonNames = ["New Moon", "First Quarter Moon", "Full Moon", "Last Quarter Moon"]

// Every phase that falls on a local calendar day of the year.
function moonPhases(year) {
    var out = []
    var k0 = Math.floor((year - 2000) * 12.3685) - 2
    for (var step = 0; step < 4 * 16; step++) {
        var k = k0 + step / 4
        var date = moonPhaseDate(k)
        if (date.getFullYear() === year)
            out.push({ date: date, name: moonNames[step % 4] })
    }
    return out
}

// ---- Year assembly ----

function build(year) {
    var map = {}
    function add(month0, day, title, kind, time) {
        var k = key(month0, day)
        if (!map[k]) map[k] = []
        map[k].push({ title: title, kind: kind, time: time || "" })
    }
    function addDate(date, title, kind, time) { add(date.getMonth(), date.getDate(), title, kind, time) }

    // US federal holidays.
    add(0, 1, "New Year's Day", "holiday")
    add(0, nthWeekday(year, 0, 1, 3), "Martin Luther King Jr. Day", "holiday")
    add(1, nthWeekday(year, 1, 1, 3), "Presidents' Day", "holiday")
    add(4, lastWeekday(year, 4, 1), "Memorial Day", "holiday")
    if (year >= 2021) add(5, 19, "Juneteenth", "holiday")
    add(6, 4, "Independence Day", "holiday")
    add(8, nthWeekday(year, 8, 1, 1), "Labor Day", "holiday")
    add(9, nthWeekday(year, 9, 1, 2), "Indigenous Peoples' Day / Columbus Day", "holiday")
    add(10, 11, "Veterans Day", "holiday")
    add(10, nthWeekday(year, 10, 4, 4), "Thanksgiving", "holiday")
    add(11, 25, "Christmas Day", "holiday")

    // Widely observed days.
    var easterDate = easter(year)
    var offset = function(days) { return new Date(year, easterDate.getMonth(), easterDate.getDate() + days) }
    addDate(offset(-2), "Good Friday", "observance")
    addDate(easterDate, "Easter Sunday", "observance")
    add(1, 2, "Groundhog Day", "observance")
    add(1, 14, "Valentine's Day", "observance")
    add(2, 17, "St. Patrick's Day", "observance")
    add(3, 1, "April Fools' Day", "observance")
    add(3, 15, "Tax Day (US)", "observance")
    add(4, 5, "Cinco de Mayo", "observance")
    add(4, nthWeekday(year, 4, 0, 2), "Mother's Day", "observance")
    add(5, nthWeekday(year, 5, 0, 3), "Father's Day", "observance")
    add(9, 31, "Halloween", "observance")
    add(10, nthWeekday(year, 10, 4, 4) + 1, "Black Friday", "observance")
    if (year % 2 === 0) add(10, nthWeekday(year, 10, 1, 1) + 1, "Election Day (US)", "observance")
    add(11, 24, "Christmas Eve", "observance")
    add(11, 31, "New Year's Eve", "observance")

    // International days and civil changes.
    add(2, nthWeekday(year, 2, 0, 2), "Daylight Saving Time begins (US)", "global")
    add(10, nthWeekday(year, 10, 0, 1), "Daylight Saving Time ends (US)", "global")
    add(2, 8, "International Women's Day", "global")
    add(2, 14, "Pi Day", "global")
    add(3, 7, "World Health Day", "global")
    add(3, 22, "Earth Day", "global")
    add(4, 1, "International Workers' Day", "global")
    add(5, 5, "World Environment Day", "global")
    add(5, 8, "World Oceans Day", "global")
    add(8, 21, "International Day of Peace", "global")
    add(9, 24, "United Nations Day", "global")
    add(11, 10, "Human Rights Day", "global")

    // Lunar, religious and one-off events from the tables.
    var movable = Data.movableEvents[year] || []
    for (var i = 0; i < movable.length; i++) {
        if (movable[i][0].length > 10) {
            // A UTC instant: land on the local day, with the local time.
            var instant = new Date(movable[i][0])
            if (instant.getFullYear() === year) addDate(instant, movable[i][1], movable[i][2], formatTime(instant))
            continue
        }
        var parts = movable[i][0].split("-")
        add(Number(parts[1]) - 1, Number(parts[2]), movable[i][1], movable[i][2], movable[i][3])
    }

    // Moon phases, solstices and equinoxes, meteor showers.
    var phases = moonPhases(year)
    for (var p = 0; p < phases.length; p++)
        addDate(phases[p].date, phases[p].name, "astro", formatTime(phases[p].date))
    var seasons = Data.seasonTimes[year] || []
    for (var s = 0; s < seasons.length; s++) {
        var when = new Date(seasons[s][0])
        if (when.getFullYear() === year) addDate(when, seasons[s][1], "astro", formatTime(when))
    }
    for (var m = 0; m < Data.meteorShowers.length; m++)
        add(Data.meteorShowers[m][0] - 1, Data.meteorShowers[m][1], Data.meteorShowers[m][2] + " meteor shower peak", "astro")

    for (var day in map)
        map[day].sort(function(a, b) { return kindOrder[a.kind] - kindOrder[b.kind] })
    return map
}

function formatTime(date) {
    var h = date.getHours(), minutes = pad2(date.getMinutes())
    return (h % 12 || 12) + ":" + minutes + (h < 12 ? " AM" : " PM")
}

function yearMap(year) {
    if (!cache[year]) cache[year] = build(year)
    return cache[year]
}

// Events on a date: [{ title, kind, time }].
function eventsFor(year, month0, day) {
    return yearMap(year)[key(month0, day)] || []
}

// Highest-priority kind present on a date, or "".
function topKind(events) { return events.length ? events[0].kind : "" }

// The next events of the given kinds (all kinds when omitted), starting on the date.
function upcoming(from, count, kinds) {
    var out = []
    var day = new Date(from.getFullYear(), from.getMonth(), from.getDate())
    for (var i = 0; i < 400 && out.length < count; i++) {
        var list = eventsFor(day.getFullYear(), day.getMonth(), day.getDate())
        for (var j = 0; j < list.length && out.length < count; j++) {
            if (!kinds || kinds.indexOf(list[j].kind) >= 0)
                out.push({ date: new Date(day), title: list[j].title, kind: list[j].kind })
        }
        day.setDate(day.getDate() + 1)
    }
    return out
}
