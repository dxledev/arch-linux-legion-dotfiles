import QtQuick
import QtQuick.Controls
import "../services"
import "../styles"
import "../components"

Rectangle {
    id: root
    property string fontFamily: "Noto Sans"
    implicitWidth: 360
    implicitHeight: 76
    radius: 22
    color: Theme.surface

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.right: playback.left
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5
        Text {
            width: parent.width
            text: MediaService.title || "Now playing"
            color: Theme.textPrimary
            font.family: root.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: MediaService.artist || "Media"
            color: Theme.textMuted
            font.family: root.fontFamily
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }

    Button {
        id: playback
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        height: 40
        hoverEnabled: true
        enabled: MediaService.player?.canTogglePlaying ?? false
        Accessible.name: MediaService.isPlaying ? "Pause" : "Play"
        onClicked: MediaService.togglePlayback()
        background: Rectangle {
            radius: height / 2
            color: playback.down ? Theme.buttonPressed : playback.hovered ? Theme.surfaceVariant : Theme.background
        }
        contentItem: SvgIcon {
            source: MediaService.isPlaying ? "../assets/icons/player-pause.svg" : "../assets/icons/player-play.svg"
            color: Theme.accent
            size: 18
        }
    }
}
