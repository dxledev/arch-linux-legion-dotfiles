import QtQuick
import Caelestia.Config
import qs.components
import qs.services

MouseArea {
    id: root

    readonly property string popoutName: "traymenu:aether"

    implicitWidth: Tokens.font.body.small.pointSize * 2
    implicitHeight: Tokens.font.body.small.pointSize * 2
    acceptedButtons: Qt.LeftButton
    onClicked: Aether.launch()

    MaterialIcon {
        anchors.fill: parent
        animate: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "wallpaper"
        color: Colours.palette.m3secondary
        fontStyle: Tokens.font.icon.medium
        fill: 1
    }
}
