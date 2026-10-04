import QtQuick
import Quickshell

import "../styles"
import "../core"
import "../services"

Rectangle {
    id: root

    property string monitorName: (QsWindow.window as QsWindow)?.screen?.name ?? ""
    property bool monitorActive: true
    readonly property bool panelActive: IslandState.mode === IslandState.defaultMode
        ? monitorActive : monitorName === IslandState.panelMonitorName
    readonly property int mode: panelActive ? IslandState.mode : IslandState.defaultMode

    clip: true

    radius: (ThemeService.settings.radius ?? Theme.capsuleRadius) * (root.panelActive && IslandState.modal ? 1.4 : 1)
    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.background.a * (ThemeService.settings.opacity ?? 1))

    width: implicitWidth
    height: implicitHeight

    implicitWidth: viewHost.implicitWidth
    implicitHeight: viewHost.implicitHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: StatusManager.mode === "workspace" && root.mode === IslandState.defaultMode
                ? (ThemeService.settings.workspaceAnimationDuration ?? 160)
                : root.mode === IslandState.defaultMode && ["volume", "brightness", "nightlight", "keyboard"].includes(StatusManager.mode)
                    ? StatusManager.animationDuration : Theme.animationNormal
            easing.type: ["nightlight", "volume", "brightness", "keyboard"].includes(StatusManager.mode) && root.mode === IslandState.defaultMode
                ? Easing.OutCubic : Theme.animationHorizontal
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: root.mode === IslandState.defaultMode && ["volume", "brightness", "nightlight", "keyboard"].includes(StatusManager.mode)
                ? StatusManager.animationDuration : Theme.animationNormal
            easing.type: Theme.animationVertical
        }
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

        anchors.centerIn: parent
    }
}
