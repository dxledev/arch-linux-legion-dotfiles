pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property string ddcBinary: Quickshell.env("ISLAND_DDCUTIL_BIN") || "/usr/bin/ddcutil"
    readonly property string backlightBinary: Quickshell.env("ISLAND_BRIGHTNESSCTL_BIN") || "/usr/bin/brightnessctl"
    property bool detectionPending: false
    property var ddcMonitors: ({})
    property string backlightDevice: ""
    readonly property var monitors: variants.instances
    readonly property int writeDelay: Math.max(50, Number(Quickshell.env("ISLAND_BRIGHTNESS_WRITE_DELAY_MS")) || 150)

    function iconFor(value) {
        return Qt.resolvedUrl("../assets/icons/brightness-" + (value <= 25 ? "down" : value <= 65 ? "half" : "full") + ".svg");
    }

    function getMonitor(name) {
        return monitors.find(monitor => monitor.modelData.name === name);
    }

    function refresh() {
        for (const monitor of monitors) monitor.refresh();
    }

    function detect() {
        if (ddcProcess.running) detectionPending = true;
        else ddcProcess.running = true;
        if (!backlightProcess.running) backlightProcess.running = true;
    }

    Variants {
        id: variants
        model: Quickshell.screens
        MonitorBrightness {}
    }

    Process {
        id: ddcProcess
        command: [root.ddcBinary, "detect", "--brief"]
        stdout: StdioCollector { id: ddcOutput }
        stderr: StdioCollector {}
        onExited: function(code) {
            const devices = {};
            for (const block of ddcOutput.text.split(/\n\s*\n/)) {
                if (!block.startsWith("Display ")) continue;
                const bus = block.match(/I2C bus:\s*\/dev\/i2c-(\d+)/);
                const connector = block.match(/DRM connector:\s*(\S+)/);
                if (bus && connector) devices[connector[1].replace(/^card\d+-/, "")] = bus[1];
            }
            root.ddcMonitors = devices;
            root.refresh();
            if (root.detectionPending) { root.detectionPending = false; Qt.callLater(root.detect); }
        }
    }

    Process {
        id: backlightProcess
        command: [root.backlightBinary, "--class=backlight", "--list", "--machine-readable"]
        stdout: StdioCollector { id: backlightOutput }
        stderr: StdioCollector {}
        onExited: function(code) {
            root.backlightDevice = backlightOutput.text.trim().split("\n").map(line => line.split(","))
                .find(fields => fields[1] === "backlight")?.[0] ?? "";
            root.refresh();
        }
    }

    Connections {
        target: Quickshell
        function onScreensChanged() { root.detect(); }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "monitoradded" || event.name === "monitorremoved") root.detect();
        }
    }

    Component.onCompleted: detect()
}
