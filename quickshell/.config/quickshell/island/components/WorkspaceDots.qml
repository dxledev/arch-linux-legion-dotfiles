pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Hyprland
import "../core"
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
    readonly property int diameter: Math.max(1, Math.min(dotSize, IslandGeometry.compactHeight - 2))
    readonly property var entries: workspaceEntries()
    spacing: 6
    onEntriesChanged: Qt.callLater(syncEntries)
    Component.onCompleted: syncEntries()

    function workspaceEntries() {
        const states = new Map();
        if (persistent) {
            const ids = persistentIds == null
                ? Array.from({length: persistentCount}, (_, index) => index + 1)
                : [...new Set(persistentIds)].sort((a, b) => a - b).slice(0, persistentCount);
            for (const id of ids) states.set(id, false);
        }
        for (const workspace of workspaces ?? []) {
            if (workspace.id <= 0) continue;
            const occupied = (workspace.toplevels?.values.length ?? workspace.lastIpcObject?.windows ?? 0) > 0;
            if (states.has(workspace.id) || occupied || workspace.id === activeWorkspace)
                states.set(workspace.id, occupied);
        }
        if (activeWorkspace > 0 && !states.has(activeWorkspace))
            states.set(activeWorkspace, false);
        return [...states].sort((a, b) => a[0] - b[0]).map(([id, occupied]) => ({id, occupied}));
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
            objectName: "workspace-dot-" + workspaceId
            width: root.diameter + (current ? 10 : 0)
            height: root.diameter
            radius: height / 2
            color: current ? Theme.accent : occupied ? Theme.textSecondary : Theme.surface
            Accessible.name: "Workspace " + workspaceId + (current ? ", active" : occupied ? ", occupied" : ", empty")
            Behavior on width { NumberAnimation { duration: root.animationDuration; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: root.animationDuration } }
        }
    }
}
