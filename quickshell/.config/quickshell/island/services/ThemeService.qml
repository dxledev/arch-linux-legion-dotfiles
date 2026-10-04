pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../styles"
import "MonitorSelection.js" as MonitorSelection

Singleton {
    id: root
    readonly property string controller: Quickshell.env("ISLAND_THEME_SCRIPT") || Quickshell.shellDir + "/integration/island-theme"
    property string currentTheme: ""
    property var state: ({source: "system", mode: "dark", variant: "tonalspot"})
    property var settings: ({})
    readonly property var islandScreens: MonitorSelection.screensForSetting(Quickshell.screens, settings.monitor)
    property string wallpaper: ""
    readonly property string stateDirectory: Quickshell.env("ISLAND_STATE_DIR") || (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/island"
    property bool refreshPending: false
    property bool ready: false
    property bool busy: false
    property string error: ""
    property ListModel themes: ListModel {}
    property var pending: []

    function execute(args) {
        pending = [...pending, args];
        runNext();
    }

    function runNext() {
        if (worker.running || pending.length === 0)
            return;
        const args = pending[0];
        pending = pending.slice(1);
        busy = true;
        error = "";
        worker.command = [controller, ...args];
        worker.running = true;
    }

    function apply(name) { execute(["theme", name]); }
    function setSetting(key, value) { execute(["setting", key, String(value)]); }
    function refresh() {
        if (reader.running) { refreshPending = true; return; }
        reader.running = true;
    }

    function load(data) {
        state = data.theme;
        settings = data.settings;
        currentTheme = data.label;
        wallpaper = data.wallpaper;
        const c = data.colors;
        Theme.background = c.background;
        Theme.surface = c.backgroundGray || c.backgroundAlt || c.background;
        Theme.card = Theme.surface;
        Theme.textPrimary = c.foreground;
        Theme.surfaceVariant = Qt.tint(Theme.surface, Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.06));
        Theme.textSecondary = c.foregroundInactive || c.foreground;
        Theme.textMuted = c.muted || c.foregroundInactive;
        Theme.icon = Theme.textSecondary;
        Theme.iconActive = Theme.textPrimary;
        Theme.iconDisabled = Theme.textMuted;
        Theme.accent = c.primary;
        Theme.accentHover = Qt.lighter(c.primary, 1.1);
        Theme.accentPressed = Qt.darker(c.primary, 1.1);
        Theme.border = c.border || c.primary;
        Theme.borderHover = Theme.accentHover;
        Theme.borderSelected = c.primary;
        Theme.borderSubtle = Theme.surfaceVariant;
        Theme.buttonBackground = Theme.surface;
        Theme.buttonHover = Theme.surfaceVariant;
        Theme.buttonPressed = Theme.border;
        Theme.buttonSelected = c.primary;
        Theme.controlButtonHover = Theme.surfaceVariant;
        Theme.buttonText = c.foreground;
        Theme.danger = c.danger;
        Theme.dangerHover = Qt.lighter(c.danger, 1.1);
        Theme.warning = c.warning;
        Theme.success = c.success;
        Theme.sliderBackground = Theme.surfaceVariant;
        Theme.sliderFill = c.primary;
        Theme.inputBackground = Theme.surface;
        Theme.inputBorder = Theme.border;
        Theme.notificationBackground = Theme.surface;
        Theme.notificationUnread = Theme.surfaceVariant;
        Theme.progress = c.primary;
        Theme.progressBackground = Theme.surfaceVariant;
        Theme.powerDanger = c.danger;
        Theme.powerWarning = c.warning;
        Theme.wallpaperSelection = c.primary;
        Theme.wallpaperOverlay = Qt.rgba(0, 0, 0, 0.4);
        ready = true;
    }

    Process {
        id: reader
        command: [root.controller, "ui"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: function(code) {
            if (code !== 0) { root.error = stderr.text.trim(); return; }
            try { root.load(JSON.parse(stdout.text)); }
            catch (err) { root.error = String(err); }
            if (root.refreshPending) { root.refreshPending = false; Qt.callLater(root.refresh); }
        }
    }
    FileView {
        path: root.stateDirectory + "/shell-theme.json"
        watchChanges: true
        onFileChanged: { reload(); root.refresh(); WallpaperService.reload(); }
    }
    FileView {
        path: root.stateDirectory + "/settings.json"
        watchChanges: true
        onFileChanged: { reload(); root.refresh(); }
    }
    FileView {
        path: root.stateDirectory + "/wallpapers.json"
        watchChanges: true
        onFileChanged: { reload(); root.refresh(); }
    }
    Process {
        id: themeReader
        command: [root.controller, "themes"]
        stdout: StdioCollector {}
        onExited: function(code) {
            if (code !== 0) return;
            try {
                const rows = JSON.parse(stdout.text);
                root.themes.clear();
                for (const row of rows) root.themes.append(row);
            } catch (err) { root.error = String(err); }
        }
    }
    Process {
        id: worker
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: function(code) {
            root.busy = false;
            if (code !== 0) root.error = stderr.text.trim() || "Could not apply Island settings.";
            root.refresh();
            WallpaperService.reload();
            Qt.callLater(root.runNext);
        }
    }
    Component.onCompleted: {
        refresh();
        themeReader.running = true;
    }
}
