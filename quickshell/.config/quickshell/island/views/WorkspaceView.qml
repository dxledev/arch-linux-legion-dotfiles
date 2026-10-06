import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../components"
import "../core"
import "../services"
import "../styles"

Item {
    id: root
    readonly property bool dotsStyle: ThemeService.settings.workspaceStyle === "dots"
    readonly property var screen: (QsWindow.window as QsWindow)?.screen ?? WorkspaceService.screen
    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property var activeWorkspace: (WorkspaceService.showAllMonitors ? Hyprland.focusedWorkspace : monitor?.activeWorkspace)
    implicitWidth: dotsStyle ? Math.max(160, dots.width + 40) : Theme.statusWorkspaceWidth
    implicitHeight: IslandGeometry.compactHeight

    UiText {
        objectName: "workspace-label"
        anchors.centerIn: parent
        visible: !root.dotsStyle
        text: "Workspace " + (root.activeWorkspace?.name ?? StatusManager.title)
        color: Theme.textPrimary
        font.pixelSize: 13
        font.weight: Font.Medium
    }
    WorkspaceDots {
        id: dots
        anchors.centerIn: parent
        visible: root.dotsStyle
        workspaces: WorkspaceService.workspacesForMonitor(Hyprland.workspaces.values, root.monitor?.name, WorkspaceService.showAllMonitors)
        activeWorkspace: root.activeWorkspace?.id ?? 1
        persistentIds: WorkspaceService.rules.length === 0 ? null
            : WorkspaceService.persistentForMonitor(WorkspaceService.rules, root.monitor?.name, WorkspaceService.showAllMonitors)
        persistent: ThemeService.settings.workspacePersistent ?? true
        persistentCount: ThemeService.settings.workspaceCount ?? 11
        animationDuration: ThemeService.settings.workspaceAnimationDuration ?? 160
        dotSize: ThemeService.settings.workspaceDotSize ?? 8
    }
}
