import QtQuick

import "../core"
import "../services"

Item {
    id: root

    anchors.fill: parent

    property bool hovered: false
    property bool monitorActive: true
    property string monitorName: ""
    readonly property bool hoverToExpand: ThemeService.settings.hoverToExpand ?? true
    onHoverToExpandChanged: expandTimer.stop()

    function expandFromClick() {
        if (!root.enabled || !root.monitorActive || root.hoverToExpand || IslandState.mode !== IslandState.defaultMode) return;
        expandTimer.stop();
        collapseTimer.stop();
        IslandState.islandPinned = true;
        IslandController.openExpanded(root.monitorName);
    }

    Connections {
        target: IslandState
        function onModeChanged() {
            if (IslandState.mode === IslandState.defaultMode) {
                expandTimer.stop()
                collapseTimer.stop()
            }
        }
    }

    onEnabledChanged: {
        expandTimer.stop()
        collapseTimer.stop()
        if (!enabled) hovered = false
    }

    onMonitorActiveChanged: {
        if (!monitorActive) {
            expandTimer.stop()
            if (hovered) handleHoverChanged(false)
        }
    }

    function handleHoverChanged(isHovered) {

        if (!root.enabled || (isHovered && !root.monitorActive)) return

        root.hovered = isHovered

        if (IslandState.modal)
            return

        if (isHovered) {

            collapseTimer.stop()

            if (
                (IslandState.mode === IslandState.mediaControlsMode ||
                IslandState.mode === IslandState.controlCenterMode) &&
                IslandState.islandPinned
            )
                return

            if (root.hoverToExpand) expandTimer.restart()

        } else {

            expandTimer.stop()

            if (
                IslandState.mode === IslandState.mediaControlsMode ||
                IslandState.mode === IslandState.controlCenterMode
            ) {

                if (!IslandState.islandPinned)
                    collapseTimer.start()

                return
            }

            if (!IslandState.islandPinned)
                collapseTimer.start()
        }
    }

    MouseArea {
        anchors.fill: parent

        enabled: root.monitorActive
        acceptedButtons: Qt.LeftButton

        onClicked: {

            if (IslandState.modal)
                return

            if (IslandState.mode === IslandState.controlCenterMode)
                return

            if (
                IslandState.ignoreNextIslandTap &&
                IslandState.mode === IslandState.mediaControlsMode
            ) {

                IslandController.clearIgnoredTap()

                expandTimer.stop()
                collapseTimer.stop()

                return
            }

            IslandController.togglePin()

            if (IslandState.islandPinned) {

                expandTimer.stop()
                collapseTimer.stop()

                if (
                    IslandState.mode !==
                    IslandState.mediaControlsMode
                ) {
                    IslandController.openExpanded(root.monitorName)
                }

            } else {

                if (!root.hovered)
                    collapseTimer.restart()
            }
        }
    }

    Timer {
        id: expandTimer

        interval: ThemeService.settings.hoverDelay ?? 100
        repeat: false

        onTriggered: {

            if (!root.enabled || !root.monitorActive || !root.hovered || !root.hoverToExpand) return

            if (
                IslandState.mode === IslandState.mediaControlsMode &&
                IslandState.islandPinned
            )
                return

            if (IslandState.modal)
                return

            IslandController.openExpanded(root.monitorName)
        }
    }

    Timer {
        id: collapseTimer

        interval: ThemeService.settings.collapseDelay ?? 250
        repeat: false

        onTriggered: {

            if (!root.enabled || IslandState.modal || IslandState.islandPinned) return

            if (
                IslandState.mode === IslandState.mediaControlsMode ||
                IslandState.mode === IslandState.controlCenterMode
            ) {

                if (IslandState.returnToExpanded) {

                    IslandController.restoreExpanded()

                } else {

                    IslandController.reset()
                }

                return
            }

            IslandController.reset()
        }
    }
}
