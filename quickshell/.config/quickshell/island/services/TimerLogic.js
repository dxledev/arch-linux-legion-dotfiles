.pragma library

// Pure helpers behind the timer panel and TimerService: digit entry, the dial, formatting, the saved file and
// the alert text. Times are whole seconds unless a name says ms. Nothing here touches Qt, so node can test it.

var maximumSeconds = 99 * 3600 + 59 * 60 + 59
var maximumTimers = 20
var maximumLabelLength = 60
// A full turn of the dial is an hour, like a kitchen timer.
var dialMinutes = 60
// The island's ring turns to the warning colour for the last stretch.
var urgentMs = 10000
// A timer that ended this long before anyone noticed says when it ended.
var lateMs = 30000

// Alert sounds, from the freedesktop sound theme every desktop ships. The key is the file's name.
var sounds = [
    { key: "alarm-clock-elapsed", label: "Alarm clock" },
    { key: "bell", label: "Bell" },
    { key: "complete", label: "Complete" },
    { key: "message-new-instant", label: "Message" },
    { key: "phone-incoming-call", label: "Ringtone" },
    { key: "window-attention", label: "Attention" }
]
var defaultSound = sounds[0].key

// Snoozing puts a finished timer back for a few minutes; the panel offers these lengths (in seconds).
var snoozeChoices = [60, 300, 600, 900, 1800]
var defaultSnooze = 300
var maximumSnooze = 3600

function knownSound(key) {
    return sounds.some(function(sound) { return sound.key === key })
}

function soundOrDefault(key) { return knownSound(key) ? key : defaultSound }

function soundFile(directory, key) {
    return String(directory).replace(/\/+$/, "") + "/" + key + ".oga"
}

// A snooze length in seconds: whole, between a second and an hour, else the default.
function clampSnooze(seconds) {
    var value = Math.floor(Number(seconds))
    if (!isFinite(value) || value < 1) return defaultSnooze
    return Math.min(maximumSnooze, value)
}

function pad(value) { return value < 10 ? "0" + value : String(value) }

function clampSeconds(seconds) {
    var value = Math.floor(Number(seconds))
    if (!isFinite(value) || value < 0) return 0
    return Math.min(maximumSeconds, value)
}

// Digits typed so far read as hhmmss from the right, like a microwave: 1 5 0 0 is 15:00, 9 0 is 1:30.
function digitsToSeconds(digits) {
    var text = String(digits || "").replace(/\D/g, "").slice(-6)
    while (text.length < 6) text = "0" + text
    return clampSeconds(Number(text.slice(0, 2)) * 3600 + Number(text.slice(2, 4)) * 60 + Number(text.slice(4)))
}

function secondsToDigits(seconds) {
    var total = clampSeconds(seconds)
    var number = Math.floor(total / 3600) * 10000 + Math.floor(total % 3600 / 60) * 100 + total % 60
    return number > 0 ? String(number) : ""
}

// Typing works on the digit string itself, so what was typed stays put: 9 9 is "99" (1:39), and one more 9
// makes "999" (9:99, which is 10:39).
function appendDigit(digits, digit) {
    var text = String(digits || "").replace(/\D/g, "").replace(/^0+/, "")
    if (!/^[0-9]$/.test(String(digit)) || text.length >= 6) return text
    return (text + digit).replace(/^0+/, "")
}

function removeDigit(digits) {
    return String(digits || "").replace(/\D/g, "").replace(/^0+/, "").slice(0, -1)
}

function addMinutes(seconds, minutes) {
    return clampSeconds(clampSeconds(seconds) + Math.round(Number(minutes) * 60))
}

// 5:00 -> "05:00", 1 h 30 min -> "1:30:00".
function formatClock(seconds) {
    var total = clampSeconds(seconds)
    var hours = Math.floor(total / 3600), minutes = Math.floor(total % 3600 / 60)
    return (hours > 0 ? hours + ":" + pad(minutes) : pad(minutes)) + ":" + pad(total % 60)
}

// A countdown shows the second still being lived through, so it reads 00:01 until it ends.
function formatRemaining(ms) {
    return formatClock(Math.ceil(Math.max(0, Number(ms) || 0) / 1000))
}

// 5400 -> "1 h 30 min"; 90 -> "1 min 30 s".
function describe(seconds) {
    var total = clampSeconds(seconds)
    var parts = []
    if (total >= 3600) parts.push(Math.floor(total / 3600) + " h")
    if (total % 3600 >= 60) parts.push(Math.floor(total % 3600 / 60) + " min")
    if (total % 60 > 0 || parts.length === 0) parts.push(total % 60 + " s")
    return parts.join(" ")
}

// Clockwise angle in degrees from 12 o'clock to the point (dx, dy) measured from the dial's centre.
function angleAt(dx, dy) {
    var degrees = Math.atan2(dx, -dy) * 180 / Math.PI
    return degrees < 0 ? degrees + 360 : degrees
}

// Whole minutes (0-60) the dial points at. While dragging, pass the previous value: crossing 12 o'clock
// then goes on to 60 or back to 0 instead of jumping to the other end.
function dialMinutesAt(angle, previousMinutes) {
    var turned = ((Number(angle) % 360) + 360) % 360
    var minutes = Math.round(turned / 360 * dialMinutes)
    if (previousMinutes !== undefined && previousMinutes !== null) {
        var previous = Math.min(dialMinutes, Math.max(0, Number(previousMinutes) || 0))
        if (previous > 45 && minutes < 15) minutes = dialMinutes
        else if (previous < 15 && minutes > 45) minutes = 0
    }
    return Math.min(dialMinutes, Math.max(0, minutes))
}

// How much of the dial a duration fills, 0 to 1; an hour or more is the whole ring.
function dialFill(seconds) {
    return Math.min(1, clampSeconds(seconds) / (dialMinutes * 60))
}

function cleanLabel(label) {
    return String(label === undefined || label === null ? "" : label).replace(/\s+/g, " ").trim().slice(0, maximumLabelLength)
}

function makeId(now, serial) {
    return Math.floor(now).toString(36) + "-" + serial
}

// sound is the key of the sound to play when it ends, "" for none; snooze is how many seconds a snooze lasts,
// 0 when this timer's alert does not offer one.
function createTimer(id, label, seconds, keepAlert, now, sound, snooze) {
    var length = clampSeconds(seconds)
    return {
        id: String(id), label: cleanLabel(label), durationMs: length * 1000,
        startedAt: now, endsAt: now + length * 1000, indefinite: keepAlert === true,
        sound: knownSound(sound) ? sound : "",
        snooze: Number(snooze) > 0 ? clampSnooze(snooze) : 0, snoozed: false, originalMs: length * 1000,
        paused: false, pausedMs: 0
    }
}

// A paused timer keeps how much was left in pausedMs and never goes off; its endsAt is only used to keep its
// place in the order. Resuming counts the rest down from now.
function pauseTimer(timer, now) {
    if (timer.paused) return timer
    var held = {}
    for (var key in timer) held[key] = timer[key]
    held.pausedMs = remainingMs(timer, now)
    held.paused = true
    return held
}

function resumeTimer(timer, now) {
    if (!timer.paused) return timer
    var running = {}
    for (var key in timer) running[key] = timer[key]
    running.endsAt = now + timer.pausedMs
    running.paused = false
    running.pausedMs = 0
    return running
}

// The timer a snooze puts back: the same label, sound and alert, running for the snooze length. It remembers
// how long the timer it came from was, so its alert can still say what ended.
function snoozeTimer(timer, id, now) {
    var made = createTimer(id, timer.label, timer.snooze, timer.indefinite, now, timer.sound, timer.snooze)
    made.snoozed = true
    made.originalMs = timer.originalMs > 0 ? timer.originalMs : timer.durationMs
    return made
}

// The buttons an alert shows: Stop only if there is a sound to stop, Snooze only if the timer allows it.
function alertActions(timer) {
    var actions = []
    if (timer && timer.sound) actions.push({ key: "stop", text: "Stop" })
    if (timer && timer.snooze > 0) actions.push({ key: "snooze", text: "Snooze" })
    return actions
}

// The one ending first leads; paused timers come after every running one, so the island shows what is ticking.
function sortTimers(timers) {
    return timers.slice().sort(function(a, b) {
        return (a.paused ? 1 : 0) - (b.paused ? 1 : 0) || a.endsAt - b.endsAt || a.startedAt - b.startedAt
    })
}

function remainingMs(timer, now) { return timer.paused ? Math.max(0, timer.pausedMs) : Math.max(0, timer.endsAt - now) }

// How much of the timer is left, 1 down to 0.
function progress(timer, now) {
    if (!timer || !(timer.durationMs > 0)) return 0
    return Math.min(1, remainingMs(timer, now) / timer.durationMs)
}

function isUrgent(timer, now) { return !!timer && remainingMs(timer, now) <= urgentMs }

function partition(timers, now) {
    var running = [], due = []
    timers.forEach(function(timer) { (!timer.paused && timer.endsAt <= now ? due : running).push(timer) })
    return { running: sortTimers(running), due: sortTimers(due) }
}

function validTimer(item) {
    return item && typeof item === "object" && typeof item.id === "string" && item.id.length > 0
        && isFinite(item.durationMs) && item.durationMs > 0
        && isFinite(item.endsAt) && isFinite(item.startedAt)
}

// The saved file survives a shell restart; anything unreadable in it is dropped instead of breaking the rest.
function parseStored(text) {
    var data = null
    var empty = {
        timers: [], keepAlert: false, soundEnabled: false, soundName: defaultSound,
        snoozeEnabled: false, snoozeSeconds: defaultSnooze
    }
    try { data = JSON.parse(String(text || "")) } catch (error) { return empty }
    if (!data || typeof data !== "object" || Array.isArray(data)) return empty
    var seen = {}, timers = []
    var list = Array.isArray(data.timers) ? data.timers : []
    for (var index = 0; index < list.length && timers.length < maximumTimers; index++) {
        var item = list[index]
        if (!validTimer(item) || seen[item.id]) continue
        seen[item.id] = true
        timers.push({
            id: item.id, label: cleanLabel(item.label), durationMs: Number(item.durationMs),
            startedAt: Number(item.startedAt), endsAt: Number(item.endsAt), indefinite: item.indefinite === true,
            sound: knownSound(item.sound) ? item.sound : "",
            snooze: Number(item.snooze) > 0 ? clampSnooze(item.snooze) : 0, snoozed: item.snoozed === true,
            originalMs: item.originalMs > 0 ? Number(item.originalMs) : Number(item.durationMs),
            paused: item.paused === true && item.pausedMs > 0, pausedMs: item.paused === true && item.pausedMs > 0 ? Number(item.pausedMs) : 0
        })
    }
    return {
        timers: sortTimers(timers), keepAlert: data.keepAlert === true,
        soundEnabled: data.soundEnabled === true, soundName: soundOrDefault(data.soundName),
        snoozeEnabled: data.snoozeEnabled === true, snoozeSeconds: clampSnooze(data.snoozeSeconds)
    }
}

// preferences: what the panel will use for the next timer (keepAlert, soundEnabled, soundName, snoozeEnabled,
// snoozeSeconds).
function serialize(timers, preferences) {
    var prefs = preferences || {}
    return JSON.stringify({
        version: 1, keepAlert: prefs.keepAlert === true, soundEnabled: prefs.soundEnabled === true,
        soundName: soundOrDefault(prefs.soundName), snoozeEnabled: prefs.snoozeEnabled === true,
        snoozeSeconds: clampSnooze(prefs.snoozeSeconds), timers: timers
    })
}

// What the alert says. A timer noticed late (the shell was closed, the machine asleep) also says when it ended.
function alertText(timer, lateByMs, endedAtText) {
    var seconds = Math.round((timer.snoozed && timer.originalMs > 0 ? timer.originalMs : timer.durationMs) / 1000)
    var body = "Your " + describe(seconds) + " timer is up" + (timer.snoozed ? " again." : ".")
    if (lateByMs > lateMs && endedAtText) body += " It ended at " + endedAtText + "."
    return { summary: timer.label || "Timer finished", body: body }
}
