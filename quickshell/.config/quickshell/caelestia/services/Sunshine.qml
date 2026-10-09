pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int pollInterval: 2000
    property list<string> toggleCommand: [Quickshell.env("HOME") + "/bin/system-toggle-sunshine"]
    readonly property bool busy: toggleProcess.running
    readonly property string state: checkProcess.detected ? "running" : "stopped"

    function refresh(): void {
        if (!checkProcess.running)
            checkProcess.running = true;
    }

    function toggle(): void {
        if (!busy)
            toggleProcess.running = true;
    }

    function openWebUi(): void {
        Quickshell.execDetached(["/usr/bin/xdg-open", "https://localhost:47990"]);
    }

    Process {
        id: toggleProcess

        command: root.toggleCommand
        onExited: root.refresh()
    }

    Process {
        id: checkProcess

        property bool detected: false

        command: ["/usr/bin/pgrep", "-x", "sunshine"]
        running: true
        onExited: code => detected = code === 0
    }

    Timer {
        interval: root.pollInterval
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
