import QtQuick
import "../views"
import "../styles"
import "../components"
import "../services"

Item {
    id: root

    property bool expanded: false
    // Set by the island on the monitor whose clock the lyrics have taken over.
    property bool lyricsActive: false
    readonly property bool showLyrics: lyricsActive && MediaService.hasPlayer && LyricsService.hasLyrics
    // A running timer takes the clock's place; with lyrics on it shrinks to its ring, at the right of the line.
    readonly property bool timerShown: TimerService.active
    readonly property real timerSlot: timerShown ? readout.ringWidth + 12 : 0
    property real timerShift: timerSlot
    Behavior on timerShift { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
    property real lyricBlend: showLyrics ? 1 : 0
    Behavior on lyricBlend { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }

    implicitWidth: row.implicitWidth
    implicitHeight: expanded
        ? column.implicitHeight
        : row.implicitHeight


    Column {
        id: column

        anchors.centerIn: parent

        spacing: Theme.clockSpacing


        Row {
            id: row

            spacing: 8

            anchors.horizontalCenter: parent.horizontalCenter


            Cava {
                visible: MediaService.hasPlayer && !root.expanded && (ThemeService.settings.visualizer ?? true)
                
                anchors.verticalCenter: parent.verticalCenter
            }


            Item {
                implicitWidth: root.showLyrics ? lyric.implicitWidth + root.timerSlot
                    : root.timerShown ? readout.fullWidth : clock.implicitWidth
                implicitHeight: clock.implicitHeight
                width: implicitWidth
                height: implicitHeight

                ClockView {
                    id: clock

                    anchors.centerIn: parent
                    anchors.alignWhenCentered: false
                    opacity: root.showLyrics || root.timerShown ? 0 : 1
                    interactive: !root.showLyrics && !root.timerShown

                    Behavior on opacity { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
                }

                // The expanded island's timer opens the timer panel when clicked.
                TimerReadout {
                    id: readout

                    interactive: root.expanded && root.timerShown
                    anchors.verticalCenter: parent.verticalCenter
                    blend: root.lyricBlend
                    x: (1 - root.lyricBlend) * (parent.width - width) / 2 + root.lyricBlend * (parent.width - width)
                    opacity: root.timerShown ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
                }

                // Screen recording indicator, just right of the clock value; outside the layout, so
                // starting or stopping a recording never moves the clock.
                RecordingIndicator {
                    x: root.timerShown ? readout.x + readout.width + 1
                        : (parent.width + (root.showLyrics ? lyric.width : clock.width)) / 2 + 1
                    anchors.verticalCenter: parent.verticalCenter
                }

                LyricLine {
                    id: lyric

                    objectName: "island-lyric-line"
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -root.timerShift / 2
                    anchors.alignWhenCentered: false
                    maxWidth: 240
                    text: root.lyricsActive ? (LyricsService.currentLine || "\u266a") : ""
                    paused: MediaService.isPaused
                    opacity: root.showLyrics ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
                }
            }
        }


        DateView {
            visible: root.expanded
            interactive: root.expanded

            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
