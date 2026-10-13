import QtQuick

import "../core"
import "../services"

Item {
    id: root

    anchors.fill: parent

    property bool hovered: false
    property bool monitorActive: true
    property bool morphRunning: false
    property string monitorName: ""
    readonly property bool hoverToExpand: ThemeService.settings.hoverToExpand ?? true
    onHoverToExpandChanged: expandTimer.stop()

    // Hover only expands the island from its resting state. It never swaps out a media panel (that
    // stays until the cursor has been inside it and left again) and, while a lyric line stands in
    // for the clock, a click has to bring the clock back first.
    function hoverExpandAllowed() {
        return IslandState.mode !== IslandState.mediaControlsMode
            && !LyricsService.clockShowsLyrics(root.monitorName);
    }

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

            if (IslandState.mode !== IslandState.mediaControlsMode) {
                IslandState.awaitingMediaHover = false
                mediaHoverSettleTimer.stop()
            }
        }

        function onAwaitingMediaHoverChanged() {
            if (IslandState.awaitingMediaHover)
                mediaHoverSettleTimer.restart()
            else
                mediaHoverSettleTimer.stop()
        }
    }

    // If the cursor is already inside the resized media panel no hover-enter
    // event will arrive, so once the morph has settled treat that as having entered it.
    onMorphRunningChanged: {
        if (!morphRunning && root.hovered && IslandState.mode === IslandState.mediaControlsMode)
            IslandState.awaitingMediaHover = false
    }

    Timer {
        id: mediaHoverSettleTimer

        interval: 1000
        repeat: false

        onTriggered: {
            if (root.hovered && !root.morphRunning)
                IslandState.awaitingMediaHover = false
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

            // Edge sweeping past a stationary cursor mid-morph is not the user entering.
            if (IslandState.mode === IslandState.mediaControlsMode && !root.morphRunning)
                IslandState.awaitingMediaHover = false

            if (
                (IslandState.mode === IslandState.mediaControlsMode ||
                IslandState.mode === IslandState.controlCenterMode) &&
                IslandState.islandPinned
            )
                return

            if (root.hoverToExpand && root.hoverExpandAllowed()) expandTimer.restart()

        } else {

            expandTimer.stop()

            // Opened by click: keep the panel until the cursor has been inside it.
            if (
                IslandState.mode === IslandState.mediaControlsMode &&
                IslandState.awaitingMediaHover
            )
                return

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
        cursorShape: enabled && !root.hoverToExpand && IslandState.mode === IslandState.expandedMode
            ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: {

            // A click on the island takes the lyrics out of the clock and nothing else.
            if (root.monitorName !== "" && IslandState.lyricsClockMonitor === root.monitorName) {
                const showing = LyricsService.clockShowsLyrics(root.monitorName)
                IslandController.closeLyricsInIsland()
                if (showing)
                    return
            }

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

            if (!root.hoverExpandAllowed())
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
