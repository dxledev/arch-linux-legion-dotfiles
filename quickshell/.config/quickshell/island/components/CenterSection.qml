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
                implicitWidth: root.showLyrics ? lyric.implicitWidth : clock.implicitWidth
                implicitHeight: clock.implicitHeight
                width: implicitWidth
                height: implicitHeight

                ClockView {
                    id: clock

                    anchors.centerIn: parent
                    anchors.alignWhenCentered: false
                    opacity: root.showLyrics ? 0 : 1
                    interactive: !root.showLyrics

                    Behavior on opacity { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
                }

                LyricLine {
                    id: lyric

                    objectName: "island-lyric-line"
                    anchors.centerIn: parent
                    anchors.alignWhenCentered: false
                    maxWidth: 240
                    text: root.lyricsActive ? (LyricsService.currentLine || "\u266a") : ""
                    opacity: root.showLyrics ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
                }
            }
        }


        DateView {
            visible: root.expanded

            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
