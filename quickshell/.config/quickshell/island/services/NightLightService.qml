pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string toggleScript: Quickshell.env("ISLAND_NIGHTLIGHT_SCRIPT") || Quickshell.env("HOME") + "/bin/system-toggle-nightlight"
    readonly property string statePath: Quickshell.env("ISLAND_NIGHTLIGHT_STATE_FILE") || (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/system-toggle-nightlight.state"
    property bool daemonRunning: false
    property bool daemonReady: false
    readonly property bool ready: state.ready && daemonReady
    readonly property bool enabled: state.enabled && daemonRunning
    readonly property string subtitle: enabled ? "On" : "Off"
    readonly property url icon: Qt.resolvedUrl(enabled ? "../assets/icons/moon-stars.svg" : "../assets/icons/moon.svg")

    function update() {
        if (!daemonCheck.running) daemonCheck.running = true;
    }

    function toggle() {
        if (!toggleProcess.running) toggleProcess.running = true;
    }

    FileView {
        id: state
        property bool enabled: false
        property bool ready: false
        path: root.statePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { enabled = text().trim() === "on"; ready = true; root.update(); }
        onLoadFailed: { enabled = false; ready = true; }
    }

    Process {
        id: daemonCheck
        command: ["/usr/bin/pgrep", "-x", "hyprsunset"]
        stdout: StdioCollector {}
        onExited: function(code) {
            root.daemonRunning = code === 0;
            root.daemonReady = true;
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: root.update()
    }

    Component.onCompleted: update()

    Process {
        id: toggleProcess
        command: [root.toggleScript]
        stderr: StdioCollector { id: toggleError }
        onExited: function(code) {
            state.reload();
            root.update();
            if (code !== 0) console.warn("Nightlight toggle failed:", toggleError.text.trim());
        }
    }
}
