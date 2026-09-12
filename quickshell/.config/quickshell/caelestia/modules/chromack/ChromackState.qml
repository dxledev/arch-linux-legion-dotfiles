pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Shell.Chromack
import qs.services
import qs.integration

Singleton {
    id: root
    property var screen: null
    property bool isOpen: false
    property bool picking: false
    readonly property bool launcherOpen: Quickshell.screens.some(s => ShellState.forScreen(s)?.launcher ?? false)
    property int tab: 0
    property bool savePrompt: false
    property string saveName: "palette"
    property string errorMessage: ""
    readonly property alias model: model
    readonly property var data: model.state
    readonly property var options: System.chromack
    signal focusRequested

    function open(): void {
        const target = ShellState.forActive()?.modelData;
        if (!target)
            return;
        for (const monitor of Quickshell.screens) {
            const state = ShellState.forScreen(monitor);
            if (state)
                state.launcher = false;
        }
        screen = target;
        isOpen = true;
        if (!picking)
            Qt.callLater(() => focusRequested());
    }

    function toggle(): void {
        if (isOpen)
            close(false);
        else
            open();
    }

    function close(saveColors: bool): void {
        isOpen = false;
        pickerDelay.stop();
        if (picker.running)
            picker.running = false;
        picking = false;
        if (saveColors)
            model.flush();
        savePrompt = false;
    }

    function pick(): void {
        if (picking)
            return;
        errorMessage = "";
        picking = true;
        pickerDelay.restart();
    }

    function finishPick(code: int, output: string): void {
        if (isOpen && code === 0 && output.trim()) {
            if (model.setColor(output.trim(), true, false)) {
                model.flush();
                model.copy(data.hex);
            } else
                errorMessage = "The eyedropper returned an invalid color.";
        }
        picking = false;
        if (isOpen)
            Qt.callLater(() => focusRequested());
    }

    ChromackModel {
        id: model
        onError: message => root.errorMessage = message
    }
    Timer {
        id: pickerDelay
        interval: Math.max(0, root.options.duration ?? 220) + 40
        onTriggered: picker.running = true
    }
    Process {
        id: picker
        command: root.options.eyedropperCommand ?? ["/usr/bin/hyprpicker", "-a", "-b", "-f", "rgb", "-o", "#{0:02X}{1:02X}{2:02X}"]
        stdout: StdioCollector {
            id: picked
        }
        stderr: StdioCollector {
            id: pickError
        }
        onExited: (code, status) => {
            if (code !== 0 && pickError.text.trim())
                root.errorMessage = pickError.text.trim();
            root.finishPick(code, picked.text);
        }
        onRunningChanged: {
            if (!running && root.picking && !pickerDelay.running)
                restoreFallback.restart();
        }
    }
    Timer {
        id: restoreFallback
        interval: 100
        onTriggered: {
            if (root.picking && !picker.running) {
                root.errorMessage = "Could not start the eyedropper.";
                root.finishPick(-1, "");
            }
        }
    }
    Connections {
        target: Colors
        function onValuesChanged(): void {
            model.reload();
        }
    }
    Connections {
        target: Quickshell
        function onScreensChanged(): void {
            if (root.isOpen && !Quickshell.screens.includes(root.screen)) {
                root.screen = ShellState.forActive()?.modelData ?? Quickshell.screens[0] ?? null;
            }
        }
    }
}
