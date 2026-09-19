pragma Singleton

import QtQuick
import Caelestia.I18n
import qs.utils

Searcher {
    id: root

    list: entries
    useFuzzy: true
    keys: ["label", "description", "breadcrumb", "keywords"]
    weights: [4, 2, 1, 1]

    function setting(label: string, description: string, breadcrumb: string, icon: string, pageIndex: int, subPagePath: list<int>, keywords = ""): var {
        return { label, description, breadcrumb, icon, pageIndex, subPagePath, keywords };
    }

    readonly property var entries: [
        setting(Tr.tr("Wallpaper & style"), Tr.tr("Wallpaper, fonts, colours"), Tr.tr("Wallpaper & style"), "palette", 0, [], "appearance theme"),
        setting(Tr.tr("Display wallpaper"), Tr.tr("Show the wallpaper behind the shell"), Tr.tr("Wallpaper & style"), "wallpaper", 0, [], "background"),
        setting(Tr.tr("Transparency"), Tr.tr("Adjust shell transparency"), Tr.tr("Wallpaper & style"), "opacity", 0, [], "opacity"),
        setting(Tr.tr("Dark theme"), Tr.tr("Use the dark colour scheme"), Tr.tr("Wallpaper & style"), "dark_mode", 0, [], "light mode"),
        setting(Tr.tr("Wallpapers"), Tr.tr("Choose a wallpaper"), Tr.tr("Wallpaper & style"), "wallpaper", 0, [1], "background"),
        setting(Tr.tr("Colours"), Tr.tr("Choose shell colours"), Tr.tr("Wallpaper & style"), "palette", 0, [3], "color theme"),

        setting(Tr.tr("Network"), Tr.tr("Wi-Fi, ethernet, VPN"), Tr.tr("Network"), "wifi", 1, [], "connectivity internet"),
        setting(Tr.tr("Show all networks"), Tr.tr("Browse available Wi-Fi networks"), Tr.tr("Network"), "wifi", 1, [5], "wireless"),
        setting(Tr.tr("Saved networks"), Tr.tr("Manage saved Wi-Fi networks"), Tr.tr("Network"), "wifi", 1, [6], "wireless"),
        setting(Tr.tr("Add network"), Tr.tr("Connect to a hidden network"), Tr.tr("Network"), "add", 1, [2], "wifi wireless"),
        setting(Tr.tr("Add provider"), Tr.tr("Add a VPN provider"), Tr.tr("Network"), "vpn_key", 1, [4], "vpn"),
        setting(Tr.tr("Connected devices"), Tr.tr("Bluetooth, pairing"), Tr.tr("Connected devices"), "devices_other", 2, [], "bluetooth"),
        setting(Tr.tr("Pair new device"), Tr.tr("Pair a Bluetooth device"), Tr.tr("Connected devices"), "bluetooth", 2, [2], "bluetooth"),
        setting(Tr.tr("Discoverable"), Tr.tr("Allow nearby devices to find this one"), Tr.tr("Connected devices"), "visibility", 2, [], "bluetooth"),
        setting(Tr.tr("Pairable"), Tr.tr("Allow nearby devices to pair with this one"), Tr.tr("Connected devices"), "visibility", 2, [], "bluetooth"),
        setting(Tr.tr("Audio"), Tr.tr("App volumes, sound devices"), Tr.tr("Audio"), "volume_up", 3, [], "sound microphone output input"),
        setting(Tr.tr("App volumes"), Tr.tr("Manage volume for playing apps"), Tr.tr("Audio"), "volume_up", 3, [1], "sound"),

        setting(Tr.tr("Panels"), Tr.tr("Dashboard, taskbar, launcher, sidebar"), Tr.tr("Panels"), "dock_to_bottom", 6, [], "shell"),
        setting(Tr.tr("Dashboard"), Tr.tr("Configure the dashboard panel"), Tr.tr("Panels"), "dashboard", 6, [1], "panel"),
        setting(Tr.tr("Taskbar"), Tr.tr("Configure the taskbar"), Tr.tr("Panels"), "dock_to_bottom", 6, [2], "bar panel"),
        setting(Tr.tr("Launcher"), Tr.tr("Configure the launcher"), Tr.tr("Panels"), "apps", 6, [3], "panel"),
        setting(Tr.tr("Sidebar"), Tr.tr("Configure the sidebar"), Tr.tr("Panels"), "side_navigation", 6, [4], "panel"),
        setting(Tr.tr("Utilities"), Tr.tr("Configure the utilities panel"), Tr.tr("Panels"), "widgets", 6, [5], "panel"),
        setting(Tr.tr("Persistent"), Tr.tr("Keep the bar visible at all times"), Tr.tr("Panels › Taskbar"), "visibility", 6, [2], "taskbar bar always visible"),
        setting(Tr.tr("Show on hover"), Tr.tr("Reveal the bar when the cursor reaches the screen edge"), Tr.tr("Panels › Taskbar"), "visibility", 6, [2], "taskbar bar reveal"),
        setting(Tr.tr("Drag threshold"), Tr.tr("Pixels dragged before the bar reveals"), Tr.tr("Panels › Taskbar"), "drag_handle", 6, [2], "taskbar bar gesture"),
        setting(Tr.tr("Workspaces"), Tr.tr("Indicators, window icons"), Tr.tr("Panels › Taskbar"), "workspaces", 6, [2, 6], "workspace"),
        setting(Tr.tr("Workspace icons"), Tr.tr("Choose how workspace indicators are displayed"), Tr.tr("Panels › Taskbar › Workspaces"), "workspaces", 6, [2, 6], "default simple numbered active window style"),
        setting(Tr.trCtx("Shown", "number of workspaces"), Tr.tr("Number of workspaces displayed"), Tr.tr("Panels › Taskbar › Workspaces"), "workspaces", 6, [2, 6], "workspace count"),
        setting(Tr.tr("Active indicator"), Tr.tr("Show the active workspace indicator"), Tr.tr("Panels › Taskbar › Workspaces"), "workspaces", 6, [2, 6]),
        setting(Tr.tr("Active trail"), Tr.tr("Show the active workspace trail"), Tr.tr("Panels › Taskbar › Workspaces"), "workspaces", 6, [2, 6]),
        setting(Tr.tr("Occupied background"), Tr.tr("Show occupied workspace backgrounds"), Tr.tr("Panels › Taskbar › Workspaces"), "workspaces", 6, [2, 6]),
        setting(Tr.tr("Show windows"), Tr.tr("Show icons of open windows on each workspace"), Tr.tr("Panels › Taskbar › Workspaces"), "window", 6, [2, 6], "workspace icons"),
        setting(Tr.tr("Max window icons"), Tr.tr("Maximum icons on each workspace"), Tr.tr("Panels › Taskbar › Workspaces"), "window", 6, [2, 6]),
        setting(Tr.tr("Per-monitor workspaces"), Tr.tr("Show each monitor's workspaces independently"), Tr.tr("Panels › Taskbar › Workspaces"), "monitor", 6, [2, 6]),
        setting(Tr.tr("Active window"), Tr.tr("Title display, popout"), Tr.tr("Panels › Taskbar"), "web_asset", 6, [2, 7]),
        setting(Tr.tr("Tray"), Tr.tr("System tray icons"), Tr.tr("Panels › Taskbar"), "widgets", 6, [2, 8]),
        setting(Tr.tr("Status icons"), Tr.tr("Visible indicators"), Tr.tr("Panels › Taskbar"), "signal_cellular_alt", 6, [2, 9]),
        setting(Tr.tr("Clock"), Tr.tr("Date, icon, background"), Tr.tr("Panels › Taskbar"), "schedule", 6, [2, 10]),
        setting(Tr.trCtx("Compact", "taskbar active window layout"), Tr.tr("Use a compact active-window layout"), Tr.tr("Panels › Taskbar › Active window"), "web_asset", 6, [2, 7]),
        setting(Tr.trCtx("Inverted", "taskbar active window: swap the title and class order"), Tr.tr("Swap the active-window title and class order"), Tr.tr("Panels › Taskbar › Active window"), "swap_vert", 6, [2, 7]),
        setting(Tr.tr("Show on hover"), Tr.tr("Only show the active window title while hovering"), Tr.tr("Panels › Taskbar › Active window"), "visibility", 6, [2, 7], "active window"),
        setting(Tr.tr("Popout on hover"), Tr.tr("Show a window details popout when hovering"), Tr.tr("Panels › Taskbar › Active window"), "visibility", 6, [2, 7], "active window"),
        setting(Tr.trCtx("Background", "taskbar tray: draw a background behind the tray"), Tr.tr("Draw a background behind the tray"), Tr.tr("Panels › Taskbar › Tray"), "widgets", 6, [2, 8]),
        setting(Tr.tr("Recolour icons"), Tr.tr("Recolour system tray icons"), Tr.tr("Panels › Taskbar › Tray"), "palette", 6, [2, 8], "tray"),
        setting(Tr.trCtx("Compact", "taskbar tray layout"), Tr.tr("Use a compact taskbar tray layout"), Tr.tr("Panels › Taskbar › Tray"), "widgets", 6, [2, 8]),
        setting(Tr.tr("Popout on hover"), Tr.tr("Show the tray menu popout when hovering"), Tr.tr("Panels › Taskbar › Tray"), "visibility", 6, [2, 8], "tray"),
        setting(Tr.tr("Visible icons"), Tr.tr("Choose visible status icons"), Tr.tr("Panels › Taskbar › Status icons"), "signal_cellular_alt", 6, [2, 9], "status"),
        setting(Tr.tr("Popout on hover"), Tr.tr("Show a details popout when hovering the status icons"), Tr.tr("Panels › Taskbar › Status icons"), "visibility", 6, [2, 9], "status"),
        setting(Tr.trCtx("Background", "taskbar clock: draw a background behind the clock"), Tr.tr("Draw the clock background"), Tr.tr("Panels › Taskbar › Clock"), "schedule", 6, [2, 10]),
        setting(Tr.tr("Show date"), Tr.tr("Show the date in the taskbar clock"), Tr.tr("Panels › Taskbar › Clock"), "calendar_today", 6, [2, 10]),
        setting(Tr.tr("Show icon"), Tr.tr("Show the clock icon"), Tr.tr("Panels › Taskbar › Clock"), "schedule", 6, [2, 10]),
        setting(Tr.tr("Show seconds"), Tr.tr("Show seconds in the taskbar clock"), Tr.tr("Panels › Taskbar › Clock"), "schedule", 6, [2, 10]),
        setting(Tr.tr("Scroll actions"), Tr.tr("Configure workspace, volume and brightness scrolling"), Tr.tr("Panels › Taskbar"), "swap_vert", 6, [2], "scroll"),
        setting(Tr.tr("Enabled"), Tr.tr("Show the dashboard panel"), Tr.tr("Panels › Dashboard"), "toggle_on", 6, [1], "dashboard"),
        setting(Tr.tr("Show on hover"), Tr.tr("Reveal when the cursor reaches the screen edge"), Tr.tr("Panels › Dashboard"), "visibility", 6, [1], "dashboard"),
        setting(Tr.tr("Show clock seconds"), Tr.tr("Display seconds for the clock in the main panel"), Tr.tr("Panels › Dashboard"), "schedule", 6, [1]),
        setting(Tr.tr("Tabs"), Tr.tr("Choose dashboard tabs"), Tr.tr("Panels › Dashboard"), "tab", 6, [1], "media performance weather"),
        setting(Tr.tr("Performance widgets"), Tr.tr("Choose dashboard performance widgets"), Tr.tr("Panels › Dashboard"), "monitoring", 6, [1], "battery cpu gpu memory storage network"),
        setting(Tr.tr("Drag threshold"), Tr.tr("Pixels dragged before the dashboard opens"), Tr.tr("Panels › Dashboard"), "drag_handle", 6, [1], "gesture"),
        setting(Tr.tr("Enabled"), Tr.tr("Show the launcher panel"), Tr.tr("Panels › Launcher"), "toggle_on", 6, [3], "launcher"),
        setting(Tr.tr("Action prefix"), Tr.tr("Prefix used to run actions in the launcher"), Tr.tr("Panels › Launcher"), "terminal", 6, [3], "command"),
        setting(Tr.tr("Fuzzy search"), Tr.tr("Configure launcher fuzzy search categories"), Tr.tr("Panels › Launcher"), "search", 6, [3], "launcher"),
        setting(Tr.tr("Max items shown"), Tr.tr("Maximum launcher results"), Tr.tr("Panels › Launcher"), "format_list_numbered", 6, [3], "launcher"),
        setting(Tr.tr("Max wallpapers"), Tr.tr("Maximum wallpaper results"), Tr.tr("Panels › Launcher"), "wallpaper", 6, [3], "launcher"),
        setting(Tr.tr("Drag threshold"), Tr.tr("Pixels dragged before the launcher opens"), Tr.tr("Panels › Launcher"), "drag_handle", 6, [3], "gesture"),
        setting(Tr.tr("Vim keybinds"), Tr.tr("Navigate results with Ctrl+hjkl"), Tr.tr("Panels › Launcher"), "keyboard", 6, [3]),
        setting(Tr.tr("Enable dangerous actions"), Tr.tr("Allow actions that shut down or log out"), Tr.tr("Panels › Launcher"), "warning", 6, [3]),
        setting(Tr.tr("Enabled"), Tr.tr("Show the sidebar panel"), Tr.tr("Panels › Sidebar"), "toggle_on", 6, [4], "sidebar"),
        setting(Tr.tr("Drag threshold"), Tr.tr("Pixels dragged before the sidebar opens"), Tr.tr("Panels › Sidebar"), "drag_handle", 6, [4], "gesture"),
        setting(Tr.tr("Enabled"), Tr.tr("Show the utilities panel"), Tr.tr("Panels › Utilities"), "toggle_on", 6, [5], "utilities"),
        setting(Tr.tr("Keep awake"), Tr.tr("Show the idle lock toggle"), Tr.tr("Panels › Utilities"), "visibility", 6, [5], "idle"),
        setting(Tr.tr("Nightlight"), Tr.tr("Toggle nightlight"), Tr.tr("Panels › Utilities"), "nightlight", 6, [5]),
        setting(Tr.tr("Do not disturb"), Tr.tr("Silence notifications"), Tr.tr("Panels › Utilities"), "notifications_off", 6, [5], "dnd"),
        setting(Tr.tr("Screen recorder"), Tr.tr("Show the screen recorder card"), Tr.tr("Panels › Utilities"), "videocam", 6, [5]),
        setting(Tr.tr("Quick toggles"), Tr.tr("Show the quick toggles card"), Tr.tr("Panels › Utilities"), "toggle_on", 6, [5]),
        setting(Tr.tr("Wi-Fi"), Tr.tr("Toggle wireless networking"), Tr.tr("Panels › Utilities"), "wifi", 6, [5]),
        setting(Tr.tr("Bluetooth"), Tr.tr("Toggle the Bluetooth adapter"), Tr.tr("Panels › Utilities"), "bluetooth", 6, [5]),
        setting(Tr.tr("Microphone"), Tr.tr("Mute or unmute the default source"), Tr.tr("Panels › Utilities"), "mic", 6, [5]),
        setting(Tr.tr("VPN"), Tr.tr("Connect or disconnect the VPN"), Tr.tr("Panels › Utilities"), "vpn_key", 6, [5]),

        setting(Tr.tr("Apps"), Tr.tr("Default apps, favourites, hidden apps"), Tr.tr("Apps"), "apps", 7, [], "applications"),
        setting(Tr.tr("Default applications"), Tr.tr("Choose default terminal, audio, media and file manager apps"), Tr.tr("Apps"), "apps", 7, [], "defaults"),
        setting(Tr.tr("All apps"), Tr.tr("Browse installed apps, set favourites and hidden"), Tr.tr("Apps"), "apps", 7, [1], "applications library"),
        setting(Tr.tr("Services"), Tr.tr("Poll intervals, lyrics backend"), Tr.tr("Services"), "build", 8, [], "system"),
        setting(Tr.tr("Notifications"), Tr.tr("Notifications, toasts, timeouts"), Tr.tr("Services"), "notifications", 8, [1], "notification"),
        setting(Tr.tr("Show in fullscreen"), Tr.tr("Whether notifications appear over fullscreen apps"), Tr.tr("Services › Notifications"), "notifications", 8, [1], "notification fullscreen"),
        setting(Tr.tr("Expire automatically"), Tr.tr("Dismiss notifications after their timeout"), Tr.tr("Services › Notifications"), "timer", 8, [1]),
        setting(Tr.tr("Open expanded"), Tr.tr("Show notifications expanded by default"), Tr.tr("Services › Notifications"), "unfold_more", 8, [1]),
        setting(Tr.tr("Default timeout"), Tr.tr("Time before a notification dismisses"), Tr.tr("Services › Notifications"), "timer", 8, [1]),
        setting(Tr.tr("Group preview count"), Tr.tr("Notifications shown per group before collapsing"), Tr.tr("Services › Notifications"), "format_list_numbered", 8, [1]),
        setting(Tr.tr("Visible toasts"), Tr.tr("Maximum number of toasts shown at once"), Tr.tr("Services › Notifications"), "notifications", 8, [1]),
        setting(Tr.tr("Toast events"), Tr.tr("Choose notification events that show toasts"), Tr.tr("Services › Notifications"), "notifications", 8, [1], "charging game mode dnd audio vpn now playing"),
        setting(Tr.tr("Media refresh"), Tr.tr("How often the media position updates"), Tr.tr("Services"), "refresh", 8, [], "poll interval"),
        setting(Tr.tr("System stats refresh"), Tr.tr("CPU, memory and GPU update interval"), Tr.tr("Services"), "refresh", 8, [], "poll interval"),
        setting(Tr.tr("Wi-Fi rescan"), Tr.tr("How often available networks are rescanned"), Tr.tr("Services"), "wifi", 8, [], "poll interval"),
        setting(Tr.tr("Lyrics backend"), Tr.tr("Source used to fetch synced lyrics"), Tr.tr("Services"), "lyrics", 8, [], "media"),
        setting(Tr.tr("Volume step"), Tr.tr("Amount the volume changes per scroll"), Tr.tr("Services"), "volume_up", 8, [], "sound"),
        setting(Tr.tr("Brightness step"), Tr.tr("Amount the brightness changes per scroll"), Tr.tr("Services"), "brightness_6", 8, [], "display"),
        setting(Tr.tr("Language & region"), Tr.tr("UI language, weather location, display units"), Tr.tr("Language & region"), "globe", 9, [], "locale"),
        setting(Tr.tr("UI language"), Tr.tr("The language used in the shell UI"), Tr.tr("Language & region"), "translate", 9, [], "locale"),
        setting(Tr.tr("Temperature"), Tr.tr("Units for weather temperatures"), Tr.tr("Language & region"), "device_thermostat", 9, [], "units weather"),
        setting(Tr.tr("System temperatures"), Tr.tr("Units for CPU and GPU temperatures"), Tr.tr("Language & region"), "device_thermostat", 9, [], "units cpu gpu"),
        setting(Tr.tr("Data sizes"), Tr.tr("Units for data sizes and network speeds"), Tr.tr("Language & region"), "data_usage", 9, [], "units network"),
        setting(Tr.tr("Clock format"), Tr.tr("How times are shown across the shell"), Tr.tr("Language & region"), "schedule", 9, [], "time 12 24 hour"),
        setting(Tr.tr("About"), Tr.tr("System information, credits"), Tr.tr("About"), "info", 10, [], "version system")
    ]
}
