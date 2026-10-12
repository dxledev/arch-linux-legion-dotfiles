pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Shell.Chromack
import "../../core"
import "../../island"
import "../../services"

// Chromack colour state backed by the Shell.Chromack plugin that Caelestia also
// uses, so the active colour, material slots, recents and palettes are shared.
Singleton {
    id: root

    readonly property alias model: model
    readonly property var data: model.state
    property int tab: 0
    property bool savePrompt: false
    property string saveName: "palette"
    property string errorMessage: ""
    property bool picking: false
    property string pickMonitorName: ""

    function copy(value) {
        if (value)
            model.copy(value);
    }

    // The panel collapses while the eyedropper runs so it does not cover the
    // colour being picked, then reopens on the same monitor.
    function pick() {
        if (picking)
            return;
        errorMessage = "";
        savePrompt = false;
        picking = true;
        pickMonitorName = IslandState.panelMonitorName;
        IslandController.reset();
        pickerDelay.restart();
    }

    function finishPick(code, output) {
        if (code === 0 && output.trim()) {
            if (model.setColor(output.trim(), true, false)) {
                model.flush();
                model.copy(data.hex);
            } else {
                errorMessage = "The eyedropper returned an invalid color.";
            }
        }
        picking = false;
        if (IslandState.mode === IslandState.defaultMode)
            IslandController.setMode(IslandState.chromackMode, pickMonitorName);
    }

    ChromackModel {
        id: model
        onError: message => root.errorMessage = message
    }

    Timer {
        id: pickerDelay
        interval: (ThemeService.settings.islandAnimationDuration ?? 300) + 40
        onTriggered: picker.running = true
    }

    Process {
        id: picker
        command: [Quickshell.env("ISLAND_EYEDROPPER_BIN") || "/usr/bin/hyprpicker",
            "-a", "-b", "-f", "rgb", "-o", "#{0:02X}{1:02X}{2:02X}"]
        stdout: StdioCollector { id: picked }
        stderr: StdioCollector { id: pickError }
        onExited: (code, status) => {
            if (code !== 0 && pickError.text.trim())
                root.errorMessage = pickError.text.trim();
            root.finishPick(code, picked.text);
        }
        onRunningChanged: {
            if (!running && root.picking && !pickerDelay.running)
                startFallback.restart();
        }
    }

    Timer {
        id: startFallback
        interval: 100
        onTriggered: {
            if (root.picking && !picker.running) {
                root.errorMessage = "Could not start the eyedropper.";
                root.finishPick(-1, "");
            }
        }
    }
}
