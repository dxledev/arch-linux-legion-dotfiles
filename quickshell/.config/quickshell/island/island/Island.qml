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
    // The workspace section replaces the workspace OSD while it is open; the other OSDs drop below it.
    readonly property bool workspaceOsdCovered: StatusManager.mode === "workspace"
        && mode === IslandState.expandedMode && IslandState.workspacePanelOpen
    readonly property bool statusDrawerOpen: statusDrawerActive && StatusManager.visible
        && StatusManager.isTargetScreen(monitorName) && !workspaceOsdCovered
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

    readonly property int morphDuration: ThemeService.settings.islandAnimationDuration ?? 300
    // "classic" keeps the earlier panel animation: width overshoots, height eases out, the corner
    // radius snaps and panels swap in at full opacity. Anything else is the morph style.
    readonly property bool classicStyle: ThemeService.settings.panelAnimationStyle === "classic"
    // Lags mode by one event-loop turn, so Behaviors that start with a mode change still see
    // the previous mode; compact <-> expanded hops are shorter than full panel morphs.
    property int lastMode
    Component.onCompleted: lastMode = mode
    onModeChanged: Qt.callLater(() => { root.lastMode = root.mode })
    readonly property bool hopping: mode !== lastMode
        && (mode === IslandState.defaultMode || mode === IslandState.expandedMode)
        && (lastMode === IslandState.defaultMode || lastMode === IslandState.expandedMode)
    readonly property int panelMorphDuration: Math.round(morphDuration * (hopping && !classicStyle ? Theme.morphHopScale : 1))
    // How near the animated capsule is to its target size: 0 far away, 1 arrived. Compared on
    // the panel only, since height also includes the status drawer.
    readonly property real morphCloseness: 1 - Math.min(1, Math.max(
        Math.abs(panelWidth - viewHost.implicitWidth),
        Math.abs(panelHeight - viewHost.implicitHeight)) / Theme.morphRevealDistance)
    readonly property bool morphRunning: panelWidthAnimation.running || panelHeightAnimation.running
        || radiusScaleAnimation.running

    // Only the mode-driven part of the corner radius animates, so the Corner radius slider
    // stays immediate while panels still round off as they open.
    property real radiusScale: root.mode === IslandState.powerMenuMode ? 1.2
        : root.panelActive && IslandState.modal ? 1.4 : 1
    Behavior on radiusScale {
        enabled: !root.classicStyle
        NumberAnimation {
            id: radiusScaleAnimation
            duration: root.panelMorphDuration
            easing.type: Theme.morphEasing
            easing.bezierCurve: Theme.morphCurve
        }
    }

    radius: (ThemeService.settings.radius ?? Theme.capsuleRadius) * radiusScale
    color: "transparent"
    border.width: ThemeService.settings.islandBorderWidth ?? 0
    border.color: "transparent"

    width: implicitWidth
    height: implicitHeight

    implicitWidth: panelWidth
    implicitHeight: panelHeight + statusDrawerHeight

    readonly property bool osdMotion: mode === IslandState.defaultMode
        && ["volume", "brightness", "nightlight", "keyboard"].includes(StatusManager.mode)
    readonly property bool workspaceMotion: mode === IslandState.defaultMode && StatusManager.mode === "workspace"
    readonly property var panelWidthCurve: osdMotion ? Theme.curveOutCubic
        : workspaceMotion || classicStyle ? Theme.curveOutBack : Theme.morphCurve
    readonly property var panelHeightCurve: osdMotion || workspaceMotion || classicStyle || mode === IslandState.aiUsageMode
        ? Theme.curveOutCubic : Theme.morphCurve

    Behavior on panelWidth {
        NumberAnimation {
            id: panelWidthAnimation
            duration: root.workspaceMotion ? (ThemeService.settings.workspaceAnimationDuration ?? 160)
                : root.osdMotion ? StatusManager.animationDuration : root.panelMorphDuration
            easing.type: Theme.morphEasing
            easing.bezierCurve: root.panelWidthCurve
        }
    }

    Behavior on panelHeight {
        NumberAnimation {
            id: panelHeightAnimation
            duration: root.mode === IslandState.aiUsageMode
                ? Math.min(Theme.animationFast, root.morphDuration)
                : root.osdMotion ? StatusManager.animationDuration : root.panelMorphDuration
            easing.type: Theme.morphEasing
            easing.bezierCurve: root.panelHeightCurve
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
        morphRunning: root.morphRunning

        anchors.fill: parent
    }

    ViewHost {
        id: viewHost

        mode: root.mode
        monitorActive: root.monitorActive
        monitorName: root.monitorName
        morphCloseness: root.morphCloseness
        morphRunning: root.morphRunning
        morphDuration: root.morphDuration
        revealEnabled: !root.classicStyle

        anchors.horizontalCenter: panelArea.horizontalCenter
        anchors.alignWhenCentered: false
        // Keep content pinned to the top edge so height changes only move the bottom edge.
        y: 0
    }

    // Opens the expanded island's workspace section. It rides the capsule's animated bottom edge,
    // so it slides down with the section instead of jumping to the final height.
    Rectangle {
        id: workspacePill
        objectName: "workspace-panel-pill"
        readonly property bool shown: root.panelActive && root.mode === IslandState.expandedMode
        width: 88
        height: 4
        radius: height / 2
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.panelHeight - height - 5
        z: 2
        color: Theme.accent
        opacity: !shown ? 0 : pillMouse.pressed ? 0.7 : pillMouse.containsMouse || IslandState.workspacePanelOpen ? 1 : 0.85
        visible: opacity > 0
        Accessible.role: Accessible.Button
        Accessible.name: IslandState.workspacePanelOpen ? "Hide workspaces" : "Show workspaces"
        Behavior on opacity { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }

        MouseArea {
            id: pillMouse
            anchors.fill: parent
            anchors.margins: -5
            enabled: workspacePill.shown
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: IslandState.workspacePanelOpen = !IslandState.workspacePanelOpen
        }
    }

    MouseArea {
        objectName: "compact-expand-button"
        anchors.fill: parent
        z: 1
        enabled: root.panelActive && root.monitorActive && root.mode === IslandState.defaultMode
            && !islandInteraction.hoverToExpand
        visible: enabled
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const showing = LyricsService.clockShowsLyrics(root.monitorName)
            if (IslandState.lyricsClockMonitor === root.monitorName)
                IslandController.closeLyricsInIsland()
            if (!showing)
                islandInteraction.expandFromClick()
        }
    }
}
