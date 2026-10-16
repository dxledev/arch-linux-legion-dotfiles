import QtQuick
import Quickshell
import "../views"
import "../core"
import "../components"
import "../services"
import "../styles"

Item {
    id: root

    // Set by the island on the monitor whose clock the lyrics have taken over.
    property bool lyricsActive: false
    // Falls back to the clock while there is nothing to sing (loading, none found, no player).
    readonly property bool showLyrics: lyricsActive && MediaService.hasPlayer && LyricsService.hasLyrics
    // A running timer takes the clock's place; with lyrics on it shrinks to its ring, at the right of the line.
    readonly property bool timerShown: TimerService.active
    readonly property real timerSlot: timerShown ? readout.ringWidth + 12 : 0
    // Eases to timerSlot, so the line slides over instead of jumping when a timer starts or ends.
    property real timerShift: timerSlot
    Behavior on timerShift { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
    // 0 while the timer stands in for the clock, 1 once lyrics push it to the right as a ring.
    property real lyricBlend: showLyrics ? 1 : 0
    Behavior on lyricBlend { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
    readonly property real clockWidth: Math.max(ThemeService.settings.islandWidth ?? 160,
        IslandGeometry.minimumWidth(timerShown ? readout.fullWidth : clock.implicitWidth))
    // Settings -> Media sets the narrowest the Island gets while lyrics stand in for the clock.
    // A line that does not fit widens it, up to maxLyricWidth, and the next shorter line lets it
    // settle back; beyond maxLyricWidth the line scrolls.
    readonly property real lyricWidth: ThemeService.settings.lyricsIslandMinWidth ?? 340
    readonly property real lyricPadding: 32
    readonly property real screenWidth: (QsWindow.window as QsWindow)?.screen?.width ?? 1920
    readonly property real maxLyricWidth: Math.max(lyricWidth, Math.round(screenWidth * 0.6))

    implicitWidth: showLyrics
        ? Math.min(maxLyricWidth, Math.max(clockWidth, lyricWidth, lyric.contentWidth + lyricPadding + timerSlot))
        : clockWidth
    implicitHeight: IslandGeometry.compactHeight

    ClockView {
        id: clock
        anchors.centerIn: parent
        anchors.alignWhenCentered: false
        opacity: root.showLyrics || root.timerShown ? 0 : 1
        interactive: !root.showLyrics && !root.timerShown
        Behavior on opacity { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
    }

    TimerReadout {
        id: readout
        anchors.verticalCenter: parent.verticalCenter
        blend: root.lyricBlend
        x: (1 - root.lyricBlend) * (parent.width - width) / 2 + root.lyricBlend * (parent.width - width - root.lyricPadding / 2)
        opacity: root.timerShown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
    }

    // Screen recording indicator, just right of the clock value; the island's width stays as it was.
    RecordingIndicator {
        x: root.timerShown ? (root.showLyrics ? readout.x + readout.width - 4 : readout.x + readout.width + 1)
            : (parent.width + (root.showLyrics ? lyric.width : clock.width)) / 2 + 1
        anchors.verticalCenter: parent.verticalCenter
    }

    LyricLine {
        id: lyric
        objectName: "island-lyric-line"
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -root.timerShift / 2
        anchors.alignWhenCentered: false
        maxWidth: root.maxLyricWidth - root.lyricPadding - root.timerSlot
        text: root.lyricsActive ? (LyricsService.currentLine || "\u266a") : ""
        paused: MediaService.isPaused
        opacity: root.showLyrics ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
    }
}
