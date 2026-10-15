import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Keeps Hyprland's window rounding equal to the screen corner radius, the way Caelestia's
// WindowRounding does, so windows follow the rounded screen. Only acts while Island is the active
// shell mode. With radius < 0 it hands rounding back to the Hyprland config.
Scope {
    id: root

    property int radius: -1
    // 2 is a circular corner, matching the quarter circles the screen corners draw.
    property real roundingPower: 2.0
    property string hyprctlPath: "/usr/bin/hyprctl"
    property string shellModePath: Quickshell.env("HOME") + "/bin/toggle-shell-mode"
    property string hyprConfigPath: Quickshell.env("HYPR_CONFIG")
        || (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/hypr/hyprland.lua"
    property bool syncPending: false
    property bool applied: false
    property string currentMode: ""

    function requestSync(): void {
        root.syncPending = true
        Qt.callLater(root.synchronize)
    }

    function synchronize(): void {
        if (!root.syncPending || modeQuery.running || update.running) return
        root.syncPending = false
        if (root.radius < 0 && !root.applied) return
        root.currentMode = ""
        modeQuery.running = true
    }

    onRadiusChanged: requestSync()
    Component.onCompleted: requestSync()

    FileView {
        path: root.hyprConfigPath
        watchChanges: true
        onFileChanged: {
            reload()
            root.requestSync()
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") root.requestSync()
        }
    }

    Process {
        id: modeQuery
        command: ["/usr/bin/env", "HYPR_CONFIG=" + root.hyprConfigPath, root.shellModePath, "--status"]
        stdout: StdioCollector {
            onStreamFinished: root.currentMode = text.trim()
        }
        onExited: exitCode => {
            if (exitCode === 0 && root.currentMode === "island") {
                if (root.radius >= 0) {
                    root.applied = true
                    update.exec([root.hyprctlPath, "eval", "hl.config({ decoration = { rounding = " + root.radius
                        + ", rounding_power = " + root.roundingPower + " } })"])
                } else {
                    // Corners went off: reloading restores the rounding the config file asks for.
                    root.applied = false
                    update.exec([root.hyprctlPath, "reload"])
                }
            } else if (exitCode === 0) {
                // Another mode owns rounding now; its own reload already dropped ours.
                root.applied = false
            }
            Qt.callLater(root.synchronize)
        }
    }

    Process {
        id: update
        onExited: exitCode => {
            if (exitCode !== 0) console.warn("Could not sync Hyprland rounding with the Island screen corners")
            Qt.callLater(root.synchronize)
        }
    }
}
