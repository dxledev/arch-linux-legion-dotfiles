.pragma library

var maximumGridSize = 4
var maximumPins = maximumGridSize * maximumGridSize

var settingsSections = [
    { key: "launcher", title: "App launcher", icon: "../assets/icons/apps.svg" },
    { key: "menu", title: "Menu", icon: "../assets/icons/grid.svg" },
    { key: "appearance", title: "Appearance", icon: "../assets/icons/display.svg" },
    { key: "desktop", title: "Desktop", icon: "../assets/icons/laptop.svg" },
    { key: "displays", title: "Displays", icon: "../assets/icons/display.svg" },
    { key: "clock", title: "Clock", icon: "../assets/icons/clock.svg" },
    { key: "lock", title: "Lock screen", icon: "../assets/icons/lock.svg" },
    { key: "osd", title: "OSD", icon: "../assets/icons/osd.svg" },
    { key: "workspaces", title: "Workspaces", icon: "../assets/icons/workspaces.svg" },
    { key: "dynamicPalette", title: "Dynamic palette", icon: "../assets/icons/palette.svg" },
    { key: "notifications", title: "Notifications", icon: "../assets/icons/bell.svg" },
    { key: "interaction", title: "Interaction", icon: "../assets/icons/touch.svg" },
    { key: "wallpaperAnimation", title: "Wallpaper", menuTitle: "Wallpaper Settings", icon: "../assets/icons/sparkles.svg" },
    { key: "media", title: "Media", menuTitle: "Media Settings", icon: "../assets/icons/music.svg" }
]

var menuEntries = [
    { id: "themes", title: "Themes", subtitle: "Colors and palettes", keywords: ["theme", "color", "palette"], icon: "../assets/icons/palette.svg", route: { type: "controller", action: "openThemeSelector" } },
    { id: "wallpapers", title: "Wallpapers", subtitle: "Choose your backdrop", keywords: ["wallpaper", "background", "backdrop"], icon: "../assets/icons/wallpaper.svg", route: { type: "controller", action: "openWallpaperSelector" } },
    { id: "settings", title: "Settings", subtitle: "Make Island yours", keywords: ["preferences", "configuration"], icon: "../assets/icons/settings.svg", route: { type: "controller", action: "openSettings" } },
    { id: "shell-mode", title: "Shell mode", subtitle: "Switch your workspace", keywords: ["shell", "waybar", "caelestia", "noctalia", "island", "mode"], icon: "../assets/icons/shell.svg", route: { type: "controller", action: "openShellSwitcher" } },
    { id: "browse-wallpapers", title: "Browse Wallpapers", subtitle: "Search wallhaven and generate palettes", keywords: ["wallhaven", "browse", "download", "online", "search wallpapers", "backgrounds", "backdrop", "wallpaper", "palette", "pastel", "aether", "generate palette", "dynamic palette", "toplist", "random", "anime", "nature"], icon: "../assets/icons/image-search.svg", route: { type: "controller", action: "openWallhaven" } },
    { id: "layout", title: "Layout", subtitle: "Choose a window tiling layout", keywords: ["layout", "tiling", "tile", "windows", "dwindle", "scrolling", "master", "monocle", "grid", "spiral", "manual", "center stack", "centerstack", "hyprland"], icon: "../assets/icons/layout.svg", route: { type: "controller", action: "openLayoutSwitcher" } },
    { id: "keybinds", title: "Keybinds", subtitle: "Global and Island shortcuts", keywords: ["keybind", "keybindings", "shortcuts", "keyboard", "hyprland"], icon: "../assets/icons/keyboard.svg", route: { type: "controller", action: "openKeybinds" } },
    { id: "workspace-axis", title: "Workspace Axis", subtitle: "Choose workspace movement direction", keywords: ["workspace", "axis", "horizontal", "vertical", "direction", "animation", "hyprland"], icon: "../assets/icons/workspaces.svg", route: { type: "controller", action: "openWorkspaceAxis" } },
    { id: "launcher", title: "App launcher", subtitle: "Search and launch apps", keywords: ["apps", "applications", "launch", "search"], icon: "../assets/icons/apps.svg", route: { type: "controller", action: "openLauncher" } },
    { id: "control-center", title: "Control Center", subtitle: "Quick controls and status", keywords: ["wifi", "bluetooth", "microphone", "night light", "idle lock", "brightness", "volume", "notifications"], icon: "../assets/icons/control-center.svg", route: { type: "controller", action: "openControlCenter" } },
    { id: "audio-devices", title: "Audio devices", subtitle: "Choose output and input", keywords: ["audio", "sound", "speaker", "headphones", "microphone", "output", "input"], icon: "../assets/icons/volume-2.svg", route: { type: "controller", action: "openAudioDevices" } },
    { id: "wifi", title: "Wi-Fi", subtitle: "Networks and connections", keywords: ["wifi", "wi-fi", "wireless", "network", "internet", "ssid", "connect"], icon: "../assets/icons/wifi.svg", route: { type: "controller", action: "openWifi" } },
    { id: "bluetooth", title: "Bluetooth", subtitle: "Devices and pairing", keywords: ["bluetooth", "bt", "pair", "pairing", "headphones", "earbuds", "speaker", "controller", "mouse", "keyboard", "devices", "wireless"], icon: "../assets/icons/bluetooth.svg", route: { type: "controller", action: "openBluetooth" } },
    { id: "clipboard", title: "Clipboard", subtitle: "History, pins and previews", keywords: ["clipboard", "clip", "cliphist", "copy", "paste", "history", "pinned", "favorites", "snippets", "images", "links"], icon: "../assets/icons/clipboard.svg", route: { type: "controller", action: "openClipboard" } },
    { id: "chromack", title: "Chromack", subtitle: "Color picker, shades, palettes and theory", keywords: ["chromack", "color", "colour", "picker", "color picker", "eyedropper", "hex", "rgba", "shades", "tints", "tones", "palette", "theory", "complementary", "swatch"], icon: "../assets/icons/pipette.svg", route: { type: "controller", action: "openChromack" } },
    { id: "network-speed-test", title: "Network speed test", subtitle: "Measure download and upload", keywords: ["speed", "speedtest", "speed test", "internet", "bandwidth", "download", "upload", "mbps", "network", "wifi", "fast.com"], icon: "../assets/icons/gauge.svg", route: { type: "controller", action: "openNetworkSpeedTest" } },
    { id: "disk-speed-test", title: "Disk speed test", subtitle: "Measure read and write throughput", keywords: ["speed", "speedtest", "speed test", "disk", "drive", "ssd", "nvme", "storage", "read", "write", "benchmark"], icon: "../assets/icons/disk.svg", route: { type: "controller", action: "openDiskSpeedTest" } },
    { id: "power-profile", title: "Power profile", subtitle: "Battery, balanced or performance", keywords: ["battery", "power profile", "power", "profile", "performance", "balanced", "power saver", "powersave", "energy", "charging", "laptop", "boost"], icon: "../assets/icons/battery-charging.svg", route: { type: "controller", action: "openPowerProfile" } },
    { id: "proton-vpn", title: "Proton VPN", subtitle: "Connect, disconnect and choose a country", keywords: ["protonvpn", "proton", "vpn", "privacy", "tunnel", "kill switch", "killswitch", "secure", "connection", "country", "location", "ip"], icon: "../assets/icons/shield-lock.svg", route: { type: "controller", action: "openProtonVpn" } },
    { id: "session", title: "Session", subtitle: "Power and session actions", keywords: ["power", "reboot", "restart", "shutdown", "lock", "nightlight", "system"], icon: "../assets/icons/power.svg", route: { type: "controller", action: "openPowerMenu" } },
    { id: "system", title: "System", subtitle: "CPU, memory, and storage", keywords: ["stats", "statistics", "hardware", "resources", "performance", "processor", "cpu", "memory", "ram", "disk", "storage", "uptime"], icon: "../assets/icons/display.svg", route: { type: "controller", action: "openSystem" } },
    { id: "ai-usage", title: "AI Usage", subtitle: "Provider quotas and reset times", keywords: ["ai", "usage", "provider", "quota", "limits", "credits", "tokens", "codex", "openai", "claude", "anthropic", "gemini", "copilot", "cursor"], icon: "../assets/icons/sparkles.svg", route: { type: "controller", action: "openAIUsage" } },
    { id: "calendar", title: "Calendar", subtitle: "Dates, holidays, events and tasks", keywords: ["calendar", "date", "dates", "month", "today", "holiday", "holidays", "events", "event", "agenda", "schedule", "tasks", "task", "todo", "to-do", "reminders", "dashboard", "moon", "planner", "weather", "forecast"], icon: "../assets/icons/calendar.svg", route: { type: "controller", action: "openCalendar" } },
    { id: "notification-panel", title: "Notification history", subtitle: "Your recent notifications", keywords: ["notifications", "alerts", "history"], icon: "../assets/icons/bell.svg", route: { type: "controller", action: "openNotifications" } },
    { id: "media-controls", title: "Media controls", subtitle: "Playback and track controls", keywords: ["media", "music", "player", "playback", "song"], icon: "../assets/icons/music.svg", route: { type: "controller", action: "openMediaControls" } }
]

settingsSections.forEach(function(section) {
    menuEntries.push({
        id: "settings-" + section.key,
        title: section.menuTitle || section.title,
        subtitle: settingsSubtitle(section.key),
        keywords: settingsKeywords(section.key),
        icon: section.icon,
        route: { type: "settings", section: section.key }
    })
})

function settingsSubtitle(key) {
    var descriptions = {
        launcher: "App search preferences",
        menu: "Card rows and columns",
        appearance: "Fonts and Island layout",
        desktop: "Screen corners and window rounding",
        displays: "Monitors and workspaces",
        clock: "Clock format and typography",
        lock: "Lock screen preferences",
        osd: "On-screen display style and timing",
        workspaces: "Indicators and animation",
        dynamicPalette: "Wallpaper-derived colors",
        notifications: "Alerts and popup behavior",
        interaction: "Clicks and hover behavior",
        wallpaperAnimation: "Gallery layout and transitions",
        media: "Lyrics width on the Island"
    }
    return descriptions[key] || "Island preferences"
}

function settingsKeywords(key) {
    var keywords = {
        launcher: ["apps", "search", "matching", "sort"],
        menu: ["grid", "rows", "columns", "cards", "submenus", "layout"],
        appearance: ["size", "font", "width", "height", "style", "animation", "morph", "classic"],
        desktop: ["screen", "corners", "rounded", "radius", "rounding", "window", "desktop"],
        displays: ["monitor", "layout", "workspace", "resolution"],
        clock: ["time", "12 hour", "24 hour", "font"],
        lock: ["lockscreen", "screen lock", "blur", "dim"],
        osd: ["on-screen display", "volume", "brightness", "font"],
        workspaces: ["workspace", "dots", "persistent", "animation"],
        dynamicPalette: ["dynamic colors", "wallpaper colors", "palette"],
        notifications: ["alerts", "popup", "notification"],
        interaction: ["click", "hover", "gesture", "behavior"],
        wallpaperAnimation: ["transition", "wallpaper", "animation", "effects", "gallery", "grid", "rows", "columns", "scroll", "layout", "infinite", "wrap"],
        media: ["media", "music", "player", "lyrics", "song", "width", "minimum", "island", "clock"]
    }
    return keywords[key] || []
}

function filterEntries(query, entries, pinnedIds) {
    var source = entries || menuEntries
    var terms = String(query || "").trim().toLowerCase().split(/\s+/).filter(function(term) { return term.length > 0 })
    var matches = terms.length === 0 ? source.slice() : source.filter(function(entry) {
        var searchable = [entry.title, entry.subtitle].concat(entry.keywords || []).join(" ").toLowerCase()
        return terms.every(function(term) { return searchable.indexOf(term) !== -1 })
    })
    var pins = sanitizePinnedIds(pinnedIds)
    var pinnedMatches = []
    for (var index = 0; index < pins.length; index++) {
        var pinned = findEntryById(pins[index], matches)
        if (pinned) pinnedMatches.push(pinned)
    }
    return pinnedMatches.concat(matches.filter(function(entry) { return pins.indexOf(entry.id) === -1 }))
}

function findEntryById(id, entries) {
    var source = entries || menuEntries
    for (var index = 0; index < source.length; index++) {
        if (source[index].id === id) return source[index]
    }
    return null
}

function gridSize(value) {
    var size = Math.floor(Number(value))
    return size >= 2 ? Math.min(maximumGridSize, size) : 2
}

function sanitizePinnedIds(ids, entries) {
    var source = Array.isArray(ids) ? ids : []
    var result = []
    for (var index = 0; index < source.length && result.length < maximumPins; index++) {
        var id = source[index]
        var entry = findEntryById(id, entries)
        if (entry && entry.pinnable !== false && result.indexOf(id) === -1)
            result.push(id)
    }
    return result
}

function movePinnedId(pinnedIds, id, toIndex) {
    var pins = sanitizePinnedIds(pinnedIds)
    var fromIndex = pins.indexOf(id)
    if (fromIndex === -1 || typeof toIndex !== "number" || !isFinite(toIndex)) return pins
    var targetIndex = Math.max(0, Math.min(pins.length - 1, Math.floor(toIndex)))
    pins.splice(fromIndex, 1)
    pins.splice(targetIndex, 0, id)
    return pins
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

function chooseDisplayedIds(pinnedIds, eligibleIds, limit, randomFn, shuffleEligible, availableIds) {
    var maximum = limit === undefined ? 4 : Math.min(maximumPins, Math.max(0, Math.floor(Number(limit) || 0)))
    var pins = sanitizePinnedIds(pinnedIds)
    if (Array.isArray(availableIds))
        pins = pins.filter(function(id) { return availableIds.indexOf(id) !== -1 })
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
