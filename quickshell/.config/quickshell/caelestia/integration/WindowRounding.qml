import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: root

    required property int innerRadius
    property real roundingPower: 2.0
    property bool syncEnabled: true
    property string hyprctlPath: "/usr/bin/hyprctl"
    property string shellModePath: Quickshell.env("HOME") + "/bin/toggle-shell-mode"
    property string hyprConfigPath: Quickshell.env("HYPR_CONFIG")
        || (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/hypr/hyprland.lua"
    property bool syncPending: false
    property string currentMode: ""

    function requestSync(): void {
        root.syncPending = true
        Qt.callLater(root.synchronize)
    }

    function synchronize(): void {
        if (!root.syncEnabled || !root.syncPending || modeQuery.running || radiusUpdate.running) return
        root.syncPending = false
        if (root.innerRadius < 0) return
        if (!Number.isFinite(root.roundingPower) || root.roundingPower < 2 || root.roundingPower > 10) return
        root.currentMode = ""
        modeQuery.running = true
    }

    onInnerRadiusChanged: requestSync()
    onSyncEnabledChanged: requestSync()
    onRoundingPowerChanged: requestSync()
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
            if (exitCode === 0 && root.currentMode === "quickshell") {
                const config = "hl.config({ decoration = { rounding = " + root.innerRadius
                    + ", rounding_power = " + root.roundingPower + " } })"
                radiusUpdate.exec([root.hyprctlPath, "eval", config])
            }
            Qt.callLater(root.synchronize)
        }
    }

    Process {
        id: radiusUpdate
        onExited: exitCode => {
            if (exitCode !== 0) console.warn("Could not sync Hyprland rounding with Quickshell")
            Qt.callLater(root.synchronize)
        }
    }
}
