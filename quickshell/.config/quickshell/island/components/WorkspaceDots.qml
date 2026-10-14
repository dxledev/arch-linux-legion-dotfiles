pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Hyprland
import "../core"
import "../services"
import "../styles"

Row {
    id: root

    property var workspaces: Hyprland.workspaces.values
    property int activeWorkspace: Hyprland.focusedWorkspace?.id ?? 1
    property bool persistent: true
    property int persistentCount: 11
    property var persistentIds: null
    property int animationDuration: 160
    property int dotSize: 8
    property bool interactive: false
    property color emptyColor: Theme.surface
    property string namePrefix: "workspace-dot-"
    signal workspaceClicked(int workspaceId)
    readonly property int diameter: Math.max(1, Math.min(dotSize, IslandGeometry.compactHeight - 2))
    readonly property var entries: workspaceEntries()
    spacing: 6
    onEntriesChanged: Qt.callLater(syncEntries)
    Component.onCompleted: syncEntries()

    function workspaceEntries() {
        return WorkspaceService.workspaceEntries(workspaces, persistentIds, persistent, persistentCount, activeWorkspace);
    }

    function syncEntries() {
        if (!entries) return;
        for (let index = 0; index < entries.length; index++) {
            const entry = entries[index];
            if (index >= dotModel.count)
                dotModel.append({workspaceId: entry.id, occupied: entry.occupied});
            else if (dotModel.get(index).workspaceId !== entry.id || dotModel.get(index).occupied !== entry.occupied)
                dotModel.set(index, {workspaceId: entry.id, occupied: entry.occupied});
        }
        if (dotModel.count > entries.length)
            dotModel.remove(entries.length, dotModel.count - entries.length);
    }

    ListModel { id: dotModel }
    Repeater {
        model: dotModel
        Rectangle {
            required property int workspaceId
            required property bool occupied
            readonly property bool current: workspaceId === root.activeWorkspace
            objectName: root.namePrefix + workspaceId
            width: root.diameter + (current ? 10 : 0)
            height: root.diameter
            radius: height / 2
            color: current ? Theme.accent : occupied ? Theme.textSecondary : root.emptyColor
            Accessible.name: "Workspace " + workspaceId + (current ? ", active" : occupied ? ", occupied" : ", empty")
            Behavior on width { NumberAnimation { duration: root.animationDuration; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: root.animationDuration } }
            MouseArea {
                // Dots are small; the hit area reaches into the gaps and a 22 px minimum height.
                anchors.centerIn: parent
                width: parent.width + root.spacing
                height: Math.max(parent.height, 22)
                enabled: root.interactive
                cursorShape: Qt.PointingHandCursor
                onClicked: root.workspaceClicked(parent.workspaceId)
            }
        }
    }
}
