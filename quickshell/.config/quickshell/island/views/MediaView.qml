import QtQuick
import Quickshell.Widgets

import "../components"
import "../core"
import "../island"
import "../services"
import "../styles"

Item {
    id: root

    implicitWidth: 400
    implicitHeight: 212

    readonly property bool hasArt: backdrop.ready

    // Over blurred artwork the card is always dark, so text stays light on any theme.
    readonly property color primaryText: hasArt ? "#F5F5F5" : Theme.textPrimary
    readonly property color secondaryText: hasArt ? "#CFE3DF" : Theme.textSecondary
    readonly property color mutedText: hasArt ? "#9FB3AF" : Theme.textMuted

    readonly property real progress:
        MediaService.length > 0
            ? Math.max(0, Math.min(1, MediaService.position / MediaService.length))
            : 0

    ClippingRectangle {
        id: card

        anchors.fill: parent
        anchors.margins: 8

        radius: 24
        color: Theme.surface

        ArtBackdrop {
            id: backdrop

            anchors.fill: parent
            radius: card.radius
        }

        Column {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.topMargin: 16
            anchors.bottomMargin: 10

            spacing: 0

            Row {
                width: parent.width
                height: Math.max(76, info.implicitHeight)

                spacing: 18

                AlbumArt {
                    width: 76
                    height: 76
                    radius: 12
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    id: info

                    width: parent.width - 76 - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter

                    spacing: 2

                    ScrollingText {
                        text: MediaService.hasPlayer
                                ? (MediaService.title || "No Title")
                                : "Nothing Playing"

                        maxWidth: info.width
                        fontSize: 20
                        color: root.primaryText
                    }

                    UiText {
                        width: info.width
                        visible: text !== ""

                        text: MediaService.hasPlayer ? MediaService.artist : ""
                        color: root.secondaryText
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }

                    UiText {
                        width: info.width
                        visible: text !== ""

                        text: MediaService.album
                        color: root.mutedText
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    UiText {
                        width: info.width
                        visible: text !== ""

                        text: MediaService.playerName
                        color: root.mutedText
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }
            }

            SeekBar {
                width: parent.width
                height: 24

                barCenterY: 15
                progress: root.progress
                trackColor: "#33FFFFFF"
                fillColor: root.hasArt ? "#7FE3CF" : Theme.accent
                smoothDuration: 900
                seekable: MediaService.length > 0 && (MediaService.player?.canSeek ?? false)

                onSeekRequested: fraction => MediaService.seek(fraction * MediaService.length)
            }

            Item {
                width: parent.width
                height: 14

                UiText {
                    anchors.left: parent.left

                    text: MediaService.formatTime(MediaService.position)
                    color: root.secondaryText
                    font.pixelSize: 11
                }

                UiText {
                    anchors.right: parent.right

                    text: MediaService.formatTime(MediaService.length)
                    color: root.secondaryText
                    font.pixelSize: 11
                }
            }

            Item {
                width: parent.width
                height: 46

                // Opens the floating lyrics card. Closing it is the card's own button.
                Rectangle {
                    id: lyricsButton

                    objectName: "lyrics-button"
                    width: 32
                    height: 32
                    radius: 16
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    color: IslandState.lyricsOpen ? "#33FFFFFF" : lyricsHover.hovered ? "#1FFFFFFF" : "transparent"

                    activeFocusOnTab: true
                    Keys.onReturnPressed: IslandController.openLyrics()
                    Keys.onEnterPressed: IslandController.openLyrics()
                    Keys.onSpacePressed: IslandController.openLyrics()
                    FocusRing {}

                    Behavior on color { ColorAnimation { duration: Theme.animationFast } }

                    SvgIcon {
                        anchors.centerIn: parent
                        size: 17
                        source: "../assets/icons/lyrics.svg"
                        color: IslandState.lyricsOpen ? (root.hasArt ? "#7FE3CF" : Theme.accent) : root.secondaryText
                    }

                    HoverHandler {
                        id: lyricsHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: IslandController.openLyrics()
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 22

                    Item {
                        width: 32
                        height: 32
                        anchors.verticalCenter: parent.verticalCenter

                        activeFocusOnTab: true
                        Keys.onReturnPressed: MediaService.previousTrack()
                        Keys.onEnterPressed: MediaService.previousTrack()
                        Keys.onSpacePressed: MediaService.previousTrack()
                        FocusRing { radius: 16 }

                        SvgIcon {
                            anchors.centerIn: parent
                            size: 18
                            source: "../assets/icons/player-skip-back.svg"
                            color: root.primaryText
                        }

                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: MediaService.previousTrack()
                        }
                    }

                    Rectangle {
                        width: 42
                        height: 42
                        radius: 21

                        color: root.hasArt ? "#26FFFFFF" : Theme.accent

                        activeFocusOnTab: true
                        Keys.onReturnPressed: MediaService.togglePlayback()
                        Keys.onEnterPressed: MediaService.togglePlayback()
                        Keys.onSpacePressed: MediaService.togglePlayback()
                        FocusRing {}

                        SvgIcon {
                            anchors.centerIn: parent
                            size: 20

                            source:
                                MediaService.isPlaying
                                    ? "../assets/icons/player-pause.svg"
                                    : "../assets/icons/player-play.svg"

                            color: root.hasArt ? root.primaryText : Theme.background
                        }

                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: MediaService.togglePlayback()
                        }
                    }

                    Item {
                        width: 32
                        height: 32
                        anchors.verticalCenter: parent.verticalCenter

                        activeFocusOnTab: true
                        Keys.onReturnPressed: MediaService.nextTrack()
                        Keys.onEnterPressed: MediaService.nextTrack()
                        Keys.onSpacePressed: MediaService.nextTrack()
                        FocusRing { radius: 16 }

                        SvgIcon {
                            anchors.centerIn: parent
                            size: 18
                            source: "../assets/icons/player-skip-forward.svg"
                            color: root.primaryText
                        }

                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: MediaService.nextTrack()
                        }
                    }
                }
            }
        }
    }
}
