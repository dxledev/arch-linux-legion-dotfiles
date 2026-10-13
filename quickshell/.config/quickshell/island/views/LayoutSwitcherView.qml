import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "../core"
import "../styles"

FocusScope {
    id: root
    // ids are what ~/bin/menu-layout accepts for --layout
    readonly property var layouts: [
        { id: "dwindle", name: "Dwindle" },
        { id: "scrolling", name: "Scrolling" },
        { id: "master", name: "Master" },
        { id: "monocle", name: "Monocle" },
        { id: "lua:grid", name: "Grid" },
        { id: "lua:spiral", name: "Spiral" },
        { id: "lua:manual", name: "Manual" },
        { id: "lua:centerstack", name: "Center-Stack" }
    ]
    readonly property var filteredLayouts: layouts.filter(layout => layout.name.toLowerCase().includes(searchField.text.trim().toLowerCase()))
    property string currentLayout: ""
    property int selectedIndex: 0
    implicitWidth: 400
    implicitHeight: content.implicitHeight + 48
    Component.onCompleted: {
        searchField.forceActiveFocus();
        currentProcess.running = true;
    }
    onFilteredLayoutsChanged: selectedIndex = 0
    Keys.onEscapePressed: IslandController.reset()
    Keys.onDownPressed: selectedIndex = Math.min(selectedIndex + 1, filteredLayouts.length - 1)
    Keys.onUpPressed: selectedIndex = Math.max(0, selectedIndex - 1)
    Keys.onReturnPressed: activateSelected()
    Keys.onEnterPressed: activateSelected()

    function isActive(layout) {
        return layout.id === currentLayout || layout.id === "lua:" + currentLayout;
    }

    function activateLayout(layout) {
        IslandController.reset();
        Quickshell.execDetached([Quickshell.env("ISLAND_LAYOUT_SCRIPT") || Quickshell.env("HOME") + "/bin/menu-layout", "--layout", layout.id]);
    }

    function activateSelected() {
        if (selectedIndex >= 0 && selectedIndex < filteredLayouts.length)
            activateLayout(filteredLayouts[selectedIndex])
    }

    Process {
        id: currentProcess
        command: [Quickshell.env("ISLAND_HYPRCTL") || "/usr/bin/hyprctl", "-j", "getoption", "general:layout"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.currentLayout = JSON.parse(text).str || "";
                } catch (error) {
                    root.currentLayout = "";
                }
            }
        }
    }

    Column {
        id: content
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12
        PanelHeader { title: "Layout"; onBack: IslandController.openNavigation() }
        SearchField {
            id: searchField
            objectName: "layout-search"
            width: parent.width
            placeholderText: "Search layouts…"
            onNavigateDown: { focus = false; root.forceActiveFocus(); }
            onAccepted: root.activateSelected()
        }
        Repeater {
            model: root.filteredLayouts
            IslandButton {
                required property var modelData
                required property int index
                objectName: "layout-" + modelData.id
                width: parent.width
                text: modelData.name + (root.isActive(modelData) ? " · Active layout" : "")
                highlighted: root.isActive(modelData)
                focus: !searchField.activeFocus && index === root.selectedIndex
                onClicked: root.activateLayout(modelData)
            }
        }
        UiText {
            width: parent.width
            visible: root.filteredLayouts.length === 0
            text: "No layouts match your search."
            color: Theme.textSecondary
            font.pixelSize: 13
        }
    }
}
