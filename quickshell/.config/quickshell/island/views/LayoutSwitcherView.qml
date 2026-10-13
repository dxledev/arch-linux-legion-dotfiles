import QtQuick
import "../components"
import "../core"
import "../island"
import "../services"
import "../styles"

FocusScope {
    id: root
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
    readonly property string currentLayout: WorkspacePresentationService.layout
    property int selectedIndex: 0
    property string actionError: ""
    implicitWidth: 400
    implicitHeight: content.implicitHeight + 48

    Component.onCompleted: {
        searchField.forceActiveFocus()
        WorkspacePresentationService.refresh()
    }

    onFilteredLayoutsChanged: selectedIndex = 0
    Keys.onEscapePressed: IslandController.reset()
    Keys.onDownPressed: selectedIndex = Math.min(selectedIndex + 1, filteredLayouts.length - 1)
    Keys.onUpPressed: selectedIndex = Math.max(0, selectedIndex - 1)
    Keys.onReturnPressed: activateSelected()
    Keys.onEnterPressed: activateSelected()

    function isActive(layout) {
        return layout.id === WorkspacePresentationService.layout
            || layout.id === "lua:" + WorkspacePresentationService.layout
    }

    function activateLayout(layout) {
        if (WorkspacePresentationService.actionPending)
            return
        actionError = ""
        if (!WorkspacePresentationService.setLayout(layout.id))
            actionError = WorkspacePresentationService.error || "Could not set the window layout."
    }

    function activateSelected() {
        if (selectedIndex >= 0 && selectedIndex < filteredLayouts.length)
            activateLayout(filteredLayouts[selectedIndex])
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
            onNavigateDown: { focus = false; root.forceActiveFocus() }
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
                enabled: !WorkspacePresentationService.actionPending
                focus: !searchField.activeFocus && index === root.selectedIndex
                onClicked: root.activateLayout(modelData)
            }
        }

        UiText {
            objectName: "layout-error"
            width: parent.width
            visible: root.actionError.length > 0 || WorkspacePresentationService.error.length > 0
            text: root.actionError || WorkspacePresentationService.error
            color: Theme.danger
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }

        UiText {
            width: parent.width
            visible: root.filteredLayouts.length === 0
            text: "No layouts match your search."
            color: Theme.textSecondary
            font.pixelSize: 13
        }
    }

    Connections {
        target: WorkspacePresentationService
        function onActionFinished(operation, succeeded, message) {
            if (operation !== "layout" || IslandState.mode !== IslandState.layoutSwitcherMode)
                return
            if (succeeded)
                IslandController.reset()
            else
                root.actionError = message
        }
    }
}
