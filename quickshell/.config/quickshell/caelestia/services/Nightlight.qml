pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string statePath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/system-toggle-nightlight.state"
    readonly property bool enabled: state.enabled

    property list<string> toggleCommand: [Quickshell.env("HOME") + "/bin/system-toggle-nightlight"]

    function toggle(): void {
        if (!toggleProcess.running)
            toggleProcess.running = true;
    }

    Process {
        id: toggleProcess

        command: root.toggleCommand
    }

    FileView {
        id: state

        property bool enabled: false

        path: root.statePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: enabled = text().trim() === "on"
        onLoadFailed: enabled = false
    }
}
