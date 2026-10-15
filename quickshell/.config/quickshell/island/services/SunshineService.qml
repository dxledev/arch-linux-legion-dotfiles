pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string toggleScript: Quickshell.env("ISLAND_SUNSHINE_SCRIPT") || Quickshell.env("HOME") + "/bin/system-toggle-sunshine"
    readonly property string pgrepPath: Quickshell.env("ISLAND_SUNSHINE_PGREP") || "/usr/bin/pgrep"
    readonly property string systemctlPath: Quickshell.env("ISLAND_SUNSHINE_SYSTEMCTL") || "/usr/bin/systemctl"
    readonly property string unit: "app-dev.lizardbyte.app.Sunshine.service"
    readonly property string webUiUrl: "https://localhost:47990"
    // The unit sleeps 5s before launching sunshine, so "activating" already counts as on.
    property bool running: false
    readonly property bool busy: toggleProcess.running
    readonly property string subtitle: busy ? (running ? "Stopping…" : "Starting…") : running ? "Streaming host on" : "Off"
    readonly property url icon: Qt.resolvedUrl(running ? "../assets/icons/cast-connected.svg" : "../assets/icons/cast.svg")

    function refresh() {
        if (!checkProcess.running) checkProcess.running = true;
    }

    function toggle() {
        if (!busy) toggleProcess.running = true;
    }

    function openWebUi() {
        Quickshell.execDetached(["/usr/bin/xdg-open", webUiUrl]);
    }

    Process {
        id: checkProcess
        command: [root.systemctlPath, "--user", "is-active", root.unit]
        running: true
        stdout: StdioCollector { id: unitState }
        onExited: function(code) {
            const state = unitState.text.trim();
            if (state === "active" || state === "activating") root.running = true;
            else if (!pgrepProcess.running) pgrepProcess.running = true;
        }
    }

    // A sunshine started outside the unit (terminal, autostart) still counts.
    Process {
        id: pgrepProcess
        command: [root.pgrepPath, "-x", "sunshine"]
        onExited: function(code) { root.running = code === 0; }
    }

    Process {
        id: toggleProcess
        command: [root.toggleScript]
        stderr: StdioCollector { id: toggleError }
        onExited: function(code) {
            root.refresh();
            recheck.restart();
            if (code !== 0) console.warn("Sunshine toggle failed:", toggleError.text.trim());
        }
    }

    Timer {
        id: recheck
        interval: 1500
        onTriggered: root.refresh()
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }
}
