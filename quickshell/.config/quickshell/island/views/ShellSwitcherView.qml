import QtQuick
import Quickshell
import "../components"
import "../core"
import "../styles"

FocusScope {
    implicitWidth: 400
    implicitHeight: 340
    Component.onCompleted: forceActiveFocus()
    Keys.onEscapePressed: IslandController.reset()
    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12
        PanelHeader { title: "Shell mode"; onBack: IslandController.openNavigation() }
        Repeater {
            model: ["Waybar", "Caelestia", "Noctalia", "Island"]
            IslandButton {
                required property string modelData
                width: parent.width
                text: modelData + (modelData === "Island" ? " · Active shell" : "")
                highlighted: modelData === "Island"
                onClicked: {
                    IslandController.reset();
                    if (modelData !== "Island")
                        Quickshell.execDetached([Quickshell.env("SHELL_MODE_SCRIPT") || Quickshell.env("HOME") + "/bin/toggle-shell-mode", "--" + modelData.toLowerCase()]);
                }
            }
        }
    }
}
