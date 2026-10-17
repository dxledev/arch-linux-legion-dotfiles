import QtQuick
import Quickshell
import Quickshell.Io

import "../core"

Item {
    id: root

    property string layout: "EN"
    property string fullName: "English"
    property string icon: "󰌌"

    property string lastLayout: ""

    // Handles the active keymap's name; shared by the Hyprland poll and niri's event stream.
    function applyKeymap(keymap) {

        let newLayout = "EN"
        let newName = "English"

        if (keymap.startsWith("English")) {

            newLayout = "EN"
            newName = "English"

        } else if (
            keymap.startsWith("Persian") ||
            keymap.startsWith("Iranian")
        ) {

            newLayout = "FA"
            newName = "Persian"

        } else {

            newLayout = keymap.substring(0, 2).toUpperCase()
            newName = keymap
        }

        if (root.lastLayout === "") {
            root.lastLayout = newLayout
            root.layout = newLayout
            root.fullName = newName

            return
        }

        if (newLayout === root.lastLayout)
            return

        root.lastLayout = newLayout

        root.layout = newLayout
        root.fullName = newName

        StatusManager.show({
            mode: "keyboard",
            icon: root.icon,
            title: root.fullName,
            value: root.layout,

            statusWidth: 220,
            statusHeight: 33
        })
    }

    Process {
        id: layoutReader

        running: !Compositor.niri

        command: [
            "bash",
            "-c",
            "hyprctl -j devices | jq -r '.keyboards[] | select(.main == true) | .active_keymap'"
        ]

        stdout: StdioCollector {

            onStreamFinished: root.applyKeymap(text.trim())
        }
    }

    Timer {

        interval: 300

        running: !Compositor.niri

        repeat: true

        onTriggered: {

            layoutReader.running = false
            layoutReader.running = true
        }
    }

    // niri reports layout changes on its event stream, so nothing is polled there.
    Connections {
        target: NiriService
        enabled: Compositor.niri
        function onKeyboardLayoutNameChanged() {
            if (NiriService.keyboardLayoutName !== "") root.applyKeymap(NiriService.keyboardLayoutName)
        }
    }
}
