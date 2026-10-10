.pragma library

var settingsSections = [
    { key: "launcher", title: "App launcher", icon: "../assets/icons/apps.svg" },
    { key: "appearance", title: "Appearance", icon: "../assets/icons/display.svg" },
    { key: "displays", title: "Displays", icon: "../assets/icons/display.svg" },
    { key: "clock", title: "Clock", icon: "../assets/icons/clock.svg" },
    { key: "lock", title: "Lock screen", icon: "../assets/icons/lock.svg" },
    { key: "osd", title: "OSD", icon: "../assets/icons/osd.svg" },
    { key: "workspaces", title: "Workspaces", icon: "../assets/icons/workspaces.svg" },
    { key: "dynamicPalette", title: "Dynamic palette", icon: "../assets/icons/palette.svg" },
    { key: "notifications", title: "Notifications", icon: "../assets/icons/bell.svg" },
    { key: "interaction", title: "Interaction", icon: "../assets/icons/touch.svg" },
    { key: "wallpaperAnimation", title: "Wallpaper animation", icon: "../assets/icons/sparkles.svg" }
]

var menuEntries = [
    { id: "themes", title: "Themes", subtitle: "Colors and palettes", keywords: ["theme", "color", "palette"], icon: "../assets/icons/palette.svg", route: { type: "controller", action: "openThemeSelector" } },
    { id: "wallpapers", title: "Wallpapers", subtitle: "Choose your backdrop", keywords: ["wallpaper", "background", "backdrop"], icon: "../assets/icons/wallpaper.svg", route: { type: "controller", action: "openWallpaperSelector" } },
    { id: "settings", title: "Settings", subtitle: "Make Island yours", keywords: ["preferences", "configuration"], icon: "../assets/icons/settings.svg", route: { type: "controller", action: "openSettings" } },
    { id: "shell-mode", title: "Shell mode", subtitle: "Switch your workspace", keywords: ["shell", "waybar", "caelestia", "noctalia", "island", "mode"], icon: "../assets/icons/shell.svg", route: { type: "controller", action: "openShellSwitcher" } },
    { id: "launcher", title: "App launcher", subtitle: "Search and launch apps", keywords: ["apps", "applications", "launch", "search"], icon: "../assets/icons/apps.svg", route: { type: "controller", action: "openLauncher" } },
    { id: "control-center", title: "Control Center", subtitle: "Quick controls and status", keywords: ["wifi", "bluetooth", "microphone", "night light", "idle lock", "brightness", "volume", "notifications"], icon: "../assets/icons/control-center.svg", route: { type: "controller", action: "openControlCenter" } },
    { id: "audio-devices", title: "Audio devices", subtitle: "Choose output and input", keywords: ["audio", "sound", "speaker", "headphones", "microphone", "output", "input"], icon: "../assets/icons/volume-2.svg", route: { type: "controller", action: "openAudioDevices" } },
    { id: "session", title: "Session", subtitle: "Power and session actions", keywords: ["power", "reboot", "restart", "shutdown", "lock", "nightlight", "system"], icon: "../assets/icons/power.svg", route: { type: "controller", action: "openPowerMenu" } },
    { id: "system", title: "System", subtitle: "CPU, memory, and storage", keywords: ["resources", "performance", "processor", "ram", "disk", "storage", "uptime"], icon: "../assets/icons/display.svg", route: { type: "controller", action: "openSystem" } },
    { id: "notification-panel", title: "Notification history", subtitle: "Your recent notifications", keywords: ["notifications", "alerts", "history"], icon: "../assets/icons/bell.svg", route: { type: "controller", action: "openNotifications" } },
    { id: "media-controls", title: "Media controls", subtitle: "Playback and track controls", keywords: ["media", "music", "player", "playback", "song"], icon: "../assets/icons/music.svg", route: { type: "controller", action: "openMediaControls" } }
]

settingsSections.forEach(function(section) {
    menuEntries.push({
        id: "settings-" + section.key,
        title: section.title,
        subtitle: settingsSubtitle(section.key),
        keywords: settingsKeywords(section.key),
        icon: section.icon,
        route: { type: "settings", section: section.key }
    })
})

function settingsSubtitle(key) {
    var descriptions = {
        launcher: "App search preferences",
        appearance: "Fonts and Island layout",
        displays: "Monitors and workspaces",
        clock: "Clock format and typography",
        lock: "Lock screen preferences",
        osd: "On-screen display style and timing",
        workspaces: "Indicators and animation",
        dynamicPalette: "Wallpaper-derived colors",
        notifications: "Alerts and popup behavior",
        interaction: "Clicks and hover behavior",
        wallpaperAnimation: "Backdrop transitions"
    }
    return descriptions[key] || "Island preferences"
}

function settingsKeywords(key) {
    var keywords = {
        launcher: ["apps", "search", "matching", "sort"],
        appearance: ["size", "font", "width", "height", "style"],
        displays: ["monitor", "layout", "workspace", "resolution"],
        clock: ["time", "12 hour", "24 hour", "font"],
        lock: ["lockscreen", "screen lock", "blur", "dim"],
        osd: ["on-screen display", "volume", "brightness", "font"],
        workspaces: ["workspace", "dots", "persistent", "animation"],
        dynamicPalette: ["dynamic colors", "wallpaper colors", "palette"],
        notifications: ["alerts", "popup", "notification"],
        interaction: ["click", "hover", "gesture", "behavior"],
        wallpaperAnimation: ["transition", "wallpaper", "animation", "effects"]
    }
    return keywords[key] || []
}

function filterEntries(query, entries) {
    var source = entries || menuEntries
    var terms = String(query || "").trim().toLowerCase().split(/\s+/).filter(function(term) { return term.length > 0 })
    if (terms.length === 0) return source.slice()
    return source.filter(function(entry) {
        var searchable = [entry.title, entry.subtitle].concat(entry.keywords || []).join(" ").toLowerCase()
        return terms.every(function(term) { return searchable.indexOf(term) !== -1 })
    })
}

function findEntryById(id, entries) {
    var source = entries || menuEntries
    for (var index = 0; index < source.length; index++) {
        if (source[index].id === id) return source[index]
    }
    return null
}

function sanitizePinnedIds(ids, entries) {
    var source = Array.isArray(ids) ? ids : []
    var result = []
    for (var index = 0; index < source.length && result.length < 4; index++) {
        var id = source[index]
        var entry = findEntryById(id, entries)
        if (entry && entry.pinnable !== false && result.indexOf(id) === -1)
            result.push(id)
    }
    return result
}

function shuffleIds(ids, randomFn) {
    var result = Array.isArray(ids) ? ids.slice() : []
    var random = randomFn || Math.random
    for (var index = result.length - 1; index > 0; index--) {
        var randomValue = Number(random())
        if (!(randomValue >= 0)) randomValue = 0
        if (randomValue >= 1) randomValue = 0.999999999999
        var swapIndex = Math.floor(randomValue * (index + 1))
        var value = result[index]
        result[index] = result[swapIndex]
        result[swapIndex] = value
    }
    return result
}

function chooseDisplayedIds(pinnedIds, eligibleIds, limit, randomFn, shuffleEligible) {
    var maximum = limit === undefined ? 4 : Math.min(4, Math.max(0, Math.floor(Number(limit) || 0)))
    var pins = sanitizePinnedIds(pinnedIds)
    var candidates = []
    var seen = pins.slice()
    var eligible = Array.isArray(eligibleIds) ? eligibleIds : menuEntries.map(function(entry) { return entry.id })
    for (var index = 0; index < eligible.length; index++) {
        var id = eligible[index]
        if (findEntryById(id) && seen.indexOf(id) === -1) {
            candidates.push(id)
            seen.push(id)
        }
    }
    var filler = shuffleEligible === false ? candidates : shuffleIds(candidates, randomFn)
    return pins.slice(0, maximum).concat(filler.slice(0, Math.max(0, maximum - pins.length)))
}
