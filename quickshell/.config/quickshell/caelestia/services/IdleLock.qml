pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property list<string> toggleCommand: [Quickshell.env("HOME") + "/bin/system-toggle-idle-lock"]
    property int pollInterval: 1000
    readonly property bool enabled: state.enabled
    readonly property bool ready: state.ready
    readonly property bool busy: toggleProcess.running
    readonly property bool keepAwake: ready && !enabled
    property date enabledSince: new Date()

    onKeepAwakeChanged: {
        if (keepAwake)
            enabledSince = new Date();
    }

    function toggle(): void {
        if (ready && !busy)
            toggleProcess.running = true;
    }

    Process {
        id: state

        property bool enabled: true
        property bool ready: false

        command: ["/usr/bin/pgrep", "-x", "hypridle"]
        running: true
        onExited: code => {
            ready = code === 0 || code === 1;
            if (ready)
                enabled = code === 0;
        }
    }

    Process {
        id: toggleProcess

        command: root.toggleCommand
        onExited: state.running = true
    }

    Timer {
        interval: root.pollInterval
        running: true
        repeat: true
        onTriggered: {
            if (!root.busy)
                state.running = true;
        }
    }
}
