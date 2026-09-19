import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus

MouseArea {
    id: root

    readonly property string popoutName: "traymenu:nexus"

    acceptedButtons: Qt.LeftButton

    implicitWidth: Tokens.font.body.small.pointSize * 2
    implicitHeight: Tokens.font.body.small.pointSize * 2

    onClicked: WindowFactory.create()

    MaterialIcon {
        anchors.fill: parent

        animate: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        text: "settings"
        color: Colours.palette.m3onSurface
        fontStyle: Tokens.font.icon.medium
        fill: 1
    }
}
