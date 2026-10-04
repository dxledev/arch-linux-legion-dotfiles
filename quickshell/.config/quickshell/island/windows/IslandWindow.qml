import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import "../island"
import "../core"
import "../services"

PanelWindow {
    id: root

    readonly property bool monitorActive: ThemeService.islandScreens.length === 1
        || root.screen?.name === Hyprland.focusedMonitor?.name
    readonly property bool panelActive: capsule.panelActive
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
    readonly property bool hasFullscreen: WorkspaceService.hasFullscreen(root.monitor)

    WlrLayershell.namespace: "island"
    WlrLayershell.layer: WlrLayer.Overlay
    visible: ThemeService.ready && !root.hasFullscreen

    HyprlandFocusGrab {
        id: focusGrab

        active: root.visible && IslandState.modal && root.panelActive && root.monitorActive

        windows: [ root ]

        onCleared: {
            if (root.panelActive && root.monitorActive) IslandController.reset()
        }
    }

    focusable: focusGrab.active

    anchors {
        top: true
        left: true
        right: true
    }

    exclusiveZone: IslandGeometry.reservedHeight

    implicitHeight: capsule.height + IslandGeometry.topMargin

    color: "transparent"

    Island {
        id: capsule

        monitorActive: root.monitorActive
        enabled: root.visible

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: IslandGeometry.topMargin
    }

    Region {
        id: capsuleMask

        item: capsule
    }

    mask: capsuleMask

    NotificationWindow {
        screen: root.screen
        islandTop: IslandGeometry.topMargin
        islandBottom: IslandGeometry.topMargin + capsule.height
        islandWidth: capsule.width
        islandRadius: capsule.radius
    }
}
