import QtQuick
import Quickshell
import "../components"
import "../core"
import "../styles"

FocusScope {
    id: root
    readonly property var shellModes: ["Waybar", "Caelestia", "Noctalia", "Island"]
    readonly property var filteredModes: shellModes.filter(mode => mode.toLowerCase().includes(searchField.text.trim().toLowerCase()))
    property int selectedIndex: 0
    implicitWidth: 400
    implicitHeight: content.implicitHeight + 48
    Component.onCompleted: searchField.forceActiveFocus()
    onFilteredModesChanged: selectedIndex = 0
    Keys.onEscapePressed: IslandController.reset()
    Keys.onDownPressed: selectedIndex = Math.min(selectedIndex + 1, filteredModes.length - 1)
    Keys.onUpPressed: selectedIndex = Math.max(0, selectedIndex - 1)
    Keys.onReturnPressed: activateSelected()
    Keys.onEnterPressed: activateSelected()

    function activateMode(mode) {
        IslandController.reset();
        if (mode !== "Island")
            Quickshell.execDetached([Quickshell.env("SHELL_MODE_SCRIPT") || Quickshell.env("HOME") + "/bin/toggle-shell-mode", "--" + mode.toLowerCase()]);
    }

    function activateSelected() {
        if (selectedIndex >= 0 && selectedIndex < filteredModes.length)
            activateMode(filteredModes[selectedIndex])
    }

    Column {
        id: content
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12
        PanelHeader { title: "Shell mode"; onBack: IslandController.openNavigation() }
        SearchField {
            id: searchField
            width: parent.width
            placeholderText: "Search shell modes…"
            onNavigateDown: { focus = false; root.forceActiveFocus(); }
            onAccepted: root.activateSelected()
        }
        Repeater {
            model: root.filteredModes
            IslandButton {
                required property string modelData
                required property int index
                width: parent.width
                text: modelData + (modelData === "Island" ? " · Active shell" : "")
                highlighted: modelData === "Island"
                focus: !searchField.activeFocus && index === root.selectedIndex
                onClicked: root.activateMode(modelData)
            }
        }
        UiText {
            width: parent.width
            visible: root.filteredModes.length === 0
            text: "No shell modes match your search."
            color: Theme.textSecondary
            font.pixelSize: 13
        }
    }
}
