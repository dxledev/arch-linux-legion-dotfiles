pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {

    id: root

    property list<string> toggleCommand: [Quickshell.env("ISLAND_IDLE_LOCK_SCRIPT") || Quickshell.env("HOME") + "/bin/system-toggle-idle-lock"]
    property list<string> stateCommand: ["/usr/bin/pgrep", "-x", "hypridle"]
    property int pollInterval: 1000
    readonly property bool ready: stateProcess.ready
    readonly property bool busy: toggleProcess.pending || toggleProcess.running
    readonly property bool enabled: ready && stateProcess.idleLockEnabled

    readonly property string subtitle: enabled ? "On" : "Off"

    readonly property url icon: enabled
        ? Qt.resolvedUrl("../assets/icons/lock.svg")
        : Qt.resolvedUrl("../assets/icons/lock-open.svg")

    function toggle() {
        if (ready && !busy) {
            toggleProcess.pending = true;
            toggleProcess.running = true;
        }
    }

    function update() {
        if (!stateProcess.running && !busy)
            stateProcess.running = true;
    }

    Process {
        id: stateProcess
        property bool idleLockEnabled: true
        property bool ready: false
        command: root.stateCommand
        onExited: function(code) {
            ready = code === 0 || code === 1;
            if (ready)
                idleLockEnabled = code === 0;
        }
    }

    Process {
        id: toggleProcess
        property bool pending: false
        command: root.toggleCommand
        stderr: StdioCollector { id: toggleError }
        onExited: function(code) {
            pending = false;
            root.update();
            if (code !== 0)
                console.warn("Idle lock toggle failed:", toggleError.text.trim());
        }
    }

    Timer {
        interval: root.pollInterval
        running: true
        repeat: true
        onTriggered: root.update()
    }

    Component.onCompleted: update()
}
