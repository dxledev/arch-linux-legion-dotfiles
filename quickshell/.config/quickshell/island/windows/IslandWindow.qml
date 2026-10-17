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
        || root.screen?.name === Compositor.focusedMonitorName
    readonly property bool panelActive: capsule.panelActive
    readonly property var monitor: Compositor.monitorFor(root.screen)
    readonly property bool hasFullscreen: WorkspaceService.hasFullscreen(root.monitor)

    WlrLayershell.namespace: "island"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    visible: ThemeService.ready && !root.hasFullscreen

    // niri has no focus-grab protocol: the panel takes the keyboard outright and the pointer through a
    // full-screen catcher (below) that closes it, which is what the grab's `cleared` does on Hyprland.
    readonly property bool modalPanel: root.visible && IslandState.modal && root.panelActive && root.monitorActive

    HyprlandFocusGrab {
        id: focusGrab

        active: !Compositor.niri && root.modalPanel

        windows: [ root ]

        onCleared: {
            if (root.panelActive && root.monitorActive) IslandController.reset()
        }
    }

    WlrLayershell.keyboardFocus: Compositor.niri
        ? (root.modalPanel ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None)
        : (focusGrab.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)

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

    MouseArea {
        id: outsideCatcher

        anchors.fill: parent
        enabled: Compositor.niri && root.modalPanel
        acceptedButtons: Qt.AllButtons
        onPressed: IslandController.reset()
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
        // The dropdown belongs to one window: other monitors must not block clicks at its position.
        Region { item: root.panelActive && root.monitorActive ? IslandState.dropdownArea : null; radius: 18 }
    }

    Region {
        id: catcherMask
        item: outsideCatcher
    }

    mask: Compositor.niri && root.modalPanel ? catcherMask : capsuleMask

    NotificationWindow {
        screen: root.screen
        islandTop: IslandGeometry.topMargin
        islandBottom: IslandGeometry.topMargin + capsule.height
        islandWidth: capsule.width
        islandRadius: capsule.cornerRadius
    }

    LyricsWindow {
        screen: root.screen
        islandTop: IslandGeometry.topMargin
        islandBottom: IslandGeometry.topMargin + capsule.height
        islandWidth: capsule.width
        islandRadius: capsule.cornerRadius
    }

    WifiQrWindow {
        screen: root.screen
    }
}
