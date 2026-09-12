pragma Singleton

import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.I18n

Singleton {
    id: root

    property string statePath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/system-toggle-nightlight.state"
    readonly property bool enabled: state.enabled
    property bool toastEnabled: true

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
        property bool initialized: false

        path: root.statePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const nextEnabled = text().trim() === "on";
            const changed = initialized && enabled !== nextEnabled;
            enabled = nextEnabled;
            initialized = true;
            if (changed && root.toastEnabled)
                Toaster.toast(enabled ? Tr.tr("Nightlight enabled") : Tr.tr("Nightlight disabled"),
                    enabled ? Tr.tr("Warm screen colours are now on") : Tr.tr("Normal screen colours restored"),
                    enabled ? "nightlight" : "light_mode");
        }
        onLoadFailed: {
            enabled = false;
            initialized = true;
        }
    }
}
