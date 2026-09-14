pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int pollInterval: 1000
    property string processName: "aether"
    property string processUser: Quickshell.env("USER")
    readonly property bool running: checkProcess.detected
    readonly property bool busy: quitProcess.running

    function launch(): void {
        Quickshell.execDetached([Quickshell.shellPath("integration/aether"), "launch"]);
    }

    function quit(): void {
        if (!busy)
            quitProcess.running = true;
    }

    function refresh(): void {
        if (!checkProcess.running)
            checkProcess.running = true;
    }

    Process {
        id: checkProcess

        property bool detected: false

        command: root.processUser ? ["/usr/bin/pgrep", "-u", root.processUser, "-x", root.processName] : ["/usr/bin/pgrep", "-x", root.processName]
        running: true
        onExited: code => detected = code === 0
    }

    Process {
        id: quitProcess

        command: [Quickshell.shellPath("integration/aether"), "quit"]
        onExited: root.refresh()
    }

    Timer {
        interval: root.pollInterval
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
