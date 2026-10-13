import QtQuick
import "../components"
import "../core"
import "../island"
import "../services"
import "../styles"

FocusScope {
    id: root
    readonly property var axes: [
        { id: "horizontal", name: "Horizontal" },
        { id: "vertical", name: "Vertical" }
    ]
    property int selectedIndex: 0
    property string actionError: ""
    implicitWidth: 400
    implicitHeight: content.implicitHeight + 48

    Component.onCompleted: {
        forceActiveFocus()
        WorkspacePresentationService.refresh()
    }

    Keys.onEscapePressed: IslandController.reset()
    Keys.onDownPressed: selectedIndex = Math.min(selectedIndex + 1, axes.length - 1)
    Keys.onUpPressed: selectedIndex = Math.max(0, selectedIndex - 1)
    Keys.onReturnPressed: activateSelected()
    Keys.onEnterPressed: activateSelected()

    function isActive(axis) {
        return WorkspacePresentationService.effectiveAxis === axis.id
    }

    function activateAxis(axis) {
        if (WorkspacePresentationService.actionPending)
            return
        actionError = ""
        if (!WorkspacePresentationService.setAxis(axis.id))
            actionError = WorkspacePresentationService.error || "Could not set the workspace axis."
    }

    function activateSelected() {
        if (selectedIndex >= 0 && selectedIndex < axes.length)
            activateAxis(axes[selectedIndex])
    }

    Column {
        id: content
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12

        PanelHeader { title: "Workspace Axis"; onBack: IslandController.openNavigation() }

        Repeater {
            model: root.axes
            IslandButton {
                required property var modelData
                required property int index
                objectName: "workspace-axis-" + modelData.id
                width: parent.width
                text: modelData.name + (root.isActive(modelData) ? " · Active axis" : "")
                highlighted: root.isActive(modelData)
                enabled: !WorkspacePresentationService.actionPending
                focus: index === root.selectedIndex
                Accessible.name: modelData.name + (root.isActive(modelData) ? ", current workspace axis" : "")
                onClicked: root.activateAxis(modelData)
            }
        }

        UiText {
            objectName: "workspace-axis-error"
            width: parent.width
            visible: root.actionError.length > 0 || WorkspacePresentationService.error.length > 0
            text: root.actionError || WorkspacePresentationService.error
            color: Theme.danger
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }
    }

    Connections {
        target: WorkspacePresentationService
        function onActionFinished(operation, succeeded, message) {
            if (operation !== "axis" || IslandState.mode !== IslandState.workspaceAxisMode)
                return
            if (succeeded)
                IslandController.reset()
            else
                root.actionError = message
        }
    }
}
