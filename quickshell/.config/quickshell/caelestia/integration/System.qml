pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var chromack: ({})
    property var clipboard: ({
        width: 1100,
        height: 700,
        rowHeight: 64,
        listRatio: 0.48,
        durationMs: 220,
        searchDebounceMs: 150,
        historyRefreshMs: 2000,
        cliphistPath: "/usr/bin/cliphist",
        wlCopyPath: "/usr/bin/wl-copy",
        historyDatabasePath: ""
    })
    property var workspaceStarts: ({})
    property var brightnessMonitors: []
    property int brightnessWriteDelay: 100
    property int aiUsageRefreshIntervalSeconds: 300
    property int wallpaperSlideshowIntervalSeconds: 300
    property bool hasProfilePicture: false
    property bool syncWindowRounding: true
    property real windowRoundingPower: 2.0
    readonly property string home: Quickshell.env("HOME")
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || home + "/.config"
    readonly property string themeFile: Quickshell.env("SHELL_THEME_FILE") || configHome + "/themes/current/Colors.qml"
    readonly property string wallpaper: Quickshell.env("SHELL_WALLPAPER") || configHome + "/themes/current/wallpaper.png"
    readonly property string profilePicture: Quickshell.env("SHELL_PROFILE_PICTURE") || home + "/.face"
    readonly property string actionScript: Quickshell.shellPath("integration/system-action")

    function run(action: string, args: list<string>): void {
        Quickshell.execDetached([actionScript, action, ...(args || [])]);
    }

    function refreshProfile(): void {
        profileCheck.running = true;
    }

    Process {
        id: profileCheck
        command: ["/usr/bin/test", "-f", root.profilePicture]
        running: true
        onExited: code => root.hasProfilePicture = code === 0
    }

    FileView {
        path: root.configHome + "/caelestia/integration.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const config = JSON.parse(text());
            root.chromack = config.chromack || {};
            const clipboard = config.clipboard || {};
            const numberOr = (value, fallback, minimum) => {
                const number = Number(value);
                return Number.isFinite(number) ? Math.max(minimum, number) : fallback;
            };
            root.clipboard = {
                width: numberOr(clipboard.width, 1100, 1),
                height: numberOr(clipboard.height, 700, 1),
                rowHeight: numberOr(clipboard.rowHeight, 64, 56),
                listRatio: Math.min(0.65, numberOr(clipboard.listRatio, 0.48, 0.35)),
                durationMs: numberOr(clipboard.durationMs, 220, 0),
                searchDebounceMs: numberOr(clipboard.searchDebounceMs, 150, 0),
                historyRefreshMs: numberOr(clipboard.historyRefreshMs, 2000, 200),
                cliphistPath: clipboard.cliphistPath || "/usr/bin/cliphist",
                wlCopyPath: clipboard.wlCopyPath || "/usr/bin/wl-copy",
                historyDatabasePath: clipboard.historyDatabasePath || ""
            };
            root.workspaceStarts = config.workspaceStarts || {};
            root.brightnessMonitors = config.brightnessMonitors || [];
            root.brightnessWriteDelay = Math.max(50, config.brightnessWriteDelay ?? 100);
            const aiUsageInterval = Number(config.aiUsageRefreshIntervalSeconds ?? 300);
            root.aiUsageRefreshIntervalSeconds = Number.isFinite(aiUsageInterval) ? Math.max(2, Math.round(aiUsageInterval)) : 300;
            root.wallpaperSlideshowIntervalSeconds = Math.max(1, config.wallpaperSlideshowIntervalSeconds ?? 300);
            root.syncWindowRounding = config.windowRounding?.enabled ?? true;
            root.windowRoundingPower = config.windowRounding?.power ?? 2.0;
        }
    }
}
