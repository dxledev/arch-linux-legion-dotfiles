import QtQuick
import Quickshell

import "../styles"
import "../core"
import "../services"
import "../components"

Rectangle {
    id: root
    anchors.alignWhenCentered: false

    property string monitorName: (QsWindow.window as QsWindow)?.screen?.name ?? ""
    property bool monitorActive: true
    readonly property bool panelActive: IslandState.mode === IslandState.defaultMode
        ? monitorActive : monitorName === IslandState.panelMonitorName
    readonly property int mode: panelActive ? IslandState.mode : IslandState.defaultMode
    readonly property bool statusDrawerActive: mode !== IslandState.defaultMode
    readonly property bool statusDrawerOpen: statusDrawerActive && StatusManager.visible
        && StatusManager.isTargetScreen(monitorName)
    readonly property real statusDrawerHeight: statusDrawer.implicitHeight
    readonly property real statusDrawerWidth: Math.min(statusDrawer.implicitWidth,
        Math.max(0, width - 2 * (radius + 24)))
    property real panelWidth: viewHost.implicitWidth
    property real panelHeight: viewHost.implicitHeight
    readonly property color surfaceColor: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b,
        Theme.background.a * (ThemeService.settings.opacity ?? 1))
    property alias panelArea: panelArea
    property alias statusArea: statusDrawer

    clip: true

    radius: (ThemeService.settings.radius ?? Theme.capsuleRadius)
        * (root.mode === IslandState.powerMenuMode ? 1.2 : root.panelActive && IslandState.modal ? 1.4 : 1)
    color: "transparent"
    border.width: ThemeService.settings.islandBorderWidth ?? 0
    border.color: "transparent"

    width: implicitWidth
    height: implicitHeight

    implicitWidth: panelWidth
    implicitHeight: panelHeight + statusDrawerHeight

    Behavior on panelWidth {
        NumberAnimation {
            duration: StatusManager.mode === "workspace" && root.mode === IslandState.defaultMode
                ? (ThemeService.settings.workspaceAnimationDuration ?? 160)
                : root.mode === IslandState.defaultMode && ["volume", "brightness", "nightlight", "keyboard"].includes(StatusManager.mode)
                    ? StatusManager.animationDuration : (ThemeService.settings.islandAnimationDuration ?? 300)
            easing.type: ["nightlight", "volume", "brightness", "keyboard"].includes(StatusManager.mode) && root.mode === IslandState.defaultMode
                ? Easing.OutCubic : Theme.animationHorizontal
        }
    }

    Behavior on panelHeight {
        NumberAnimation {
            duration: root.mode === IslandState.defaultMode && ["volume", "brightness", "nightlight", "keyboard"].includes(StatusManager.mode)
                ? StatusManager.animationDuration : (ThemeService.settings.islandAnimationDuration ?? 300)
            easing.type: Theme.animationVertical
        }
    }

    AttachedPanelShape {
        objectName: "status-attached-surface"
        anchors.fill: parent
        panelHeight: root.panelHeight
        panelRadius: root.radius
        drawerWidth: root.statusDrawerWidth
        joinRadius: Math.min(root.radius, 16)
        borderWidth: root.border.width
        borderColor: Theme.border
        surfaceColor: root.surfaceColor
    }

    Item {
        id: panelArea
        anchors.alignWhenCentered: false
        width: root.width
        height: root.panelHeight
    }

    StatusDrawer {
        id: statusDrawer
        active: root.statusDrawerActive
        opened: root.statusDrawerOpen
        monitorName: root.monitorName
        contentWidth: root.statusDrawerWidth
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.panelHeight
        width: root.statusDrawerWidth + 2 * Math.min(root.radius, 16)
        height: root.statusDrawerHeight
    }

    HoverHandler {
        id: islandHover

        enabled: root.panelActive && root.monitorActive

        onHoveredChanged: {
            islandInteraction.handleHoverChanged(hovered)
        }
    }

    IslandInteraction {
        id: islandInteraction

        enabled: root.panelActive
        monitorActive: root.monitorActive
        monitorName: root.monitorName

        anchors.fill: parent
    }

    ViewHost {
        id: viewHost

        mode: root.mode
        monitorActive: root.monitorActive
        monitorName: root.monitorName

        anchors.centerIn: panelArea
        anchors.alignWhenCentered: false
    }

    MouseArea {
        objectName: "compact-expand-button"
        anchors.fill: parent
        z: 1
        enabled: root.panelActive && root.monitorActive && root.mode === IslandState.defaultMode
            && !islandInteraction.hoverToExpand
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: islandInteraction.expandFromClick()
    }
}
