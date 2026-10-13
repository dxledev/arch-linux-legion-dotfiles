pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "../core"
import "../island"
import "../services"
import "../styles"

// Floating lyrics card hosted under the island, one per screen. Mirrors NotificationWindow's
// geometry so the card lands exactly where a notification would.
PanelWindow {
    id: root

    required property real islandTop
    required property real islandBottom
    required property real islandWidth
    property real islandRadius: 23
    readonly property string monitorName: screen?.name ?? ""
    readonly property real islandHeight: islandBottom - islandTop
    readonly property real notificationExtent: IslandState.notificationExtents[monitorName] ?? 0
    // A notification takes the top spot under the island and pushes the lyrics card down past it,
    // leaving a fixed gap whatever the notification margin setting is.
    readonly property real notificationGap: 14
    property real notificationPush: notificationExtent > 0 ? notificationExtent + notificationGap : 0
    Behavior on notificationPush {
        NumberAnimation {
            duration: ThemeService.settings.notificationAnimationDuration ?? Theme.animationNormal
            easing.type: Theme.animationVertical
        }
    }
    readonly property real landingY: islandHeight + (ThemeService.settings.notificationMargin ?? 10)
        + (ThemeService.settings.notificationSlideDistance ?? 24) + notificationPush
    readonly property bool wanted: IslandState.lyricsOpen && IslandState.lyricsMonitorName === root.monitorName
    // Stays sized while the exit animation plays out.
    readonly property bool occupied: wanted || panel.progress > 0.001

    WlrLayershell.namespace: "island-lyrics"
    WlrLayershell.layer: WlrLayer.Top
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    focusable: false
    color: "transparent"
    anchors.top: true
    margins.top: islandTop
    implicitWidth: Math.min(ThemeService.settings.notificationWidth ?? 400, Math.max(1, (screen?.width ?? 1920) - 24))
    // The window jumps to the larger of the target and the animating card, so the card is never clipped.
    readonly property real maxCardHeight: (screen?.height ?? 1080) - islandTop - landingY - 12
    implicitHeight: occupied ? Math.min(landingY + Math.max(Math.min(IslandState.lyricsCardHeight, maxCardHeight), panel.fullHeight) + 12,
        Math.max(1, (screen?.height ?? 1080) - islandTop - 12)) : 1
    visible: ThemeService.ready
    mask: Region {
        regions: root.occupied ? [panelRegion, islandOcclusion] : []
    }

    Region {
        id: panelRegion
        item: panel.surface
        radius: panel.surface.radius
    }

    Region {
        id: islandOcclusion
        intersection: Intersection.Subtract
        x: (root.width - root.islandWidth) / 2
        width: root.islandWidth
        height: root.islandHeight
        radius: root.islandRadius
    }

    Item {
        anchors.fill: parent
        clip: true

        LyricsPanel {
            id: panel

            width: root.width
            height: root.height
            islandWidth: root.islandWidth
            islandHeight: root.islandHeight
            landingY: root.landingY
            maxHeight: root.maxCardHeight
            visible: root.occupied
            onCloseRequested: IslandController.closeLyrics()
            onExpandToggled: IslandController.toggleLyricsExpanded()
            onIslandRequested: IslandController.showLyricsInIsland()
        }
    }

    // Defer the entrance one turn so the card starts from its collapsed pose.
    Binding {
        target: panel
        property: "shown"
        value: root.wanted
        delayed: true
    }
}
