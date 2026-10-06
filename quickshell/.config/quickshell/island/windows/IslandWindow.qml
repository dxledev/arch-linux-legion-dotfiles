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
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
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
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    IslandReservation {
        screen: root.screen
        visible: root.visible
    }

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
        Region { item: capsule.panelArea }
        Region { item: capsule.statusArea }
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
