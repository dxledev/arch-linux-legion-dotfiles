pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

MouseArea {
    id: root

    required property color colour

    signal activated

    cursorShape: Qt.PointingHandCursor
    implicitHeight: icon.implicitHeight
    implicitWidth: icon.implicitWidth

    onClicked: activated()

    MaterialIcon {
        id: icon

        anchors.fill: parent
        animate: true
        color: ProtonVpn.connected ? root.colour : Colours.palette.m3onSurfaceVariant
        fill: ProtonVpn.connected ? 1 : 0
        fontStyle: Tokens.font.icon.medium
        opacity: ProtonVpn.linkKnown ? 1 : 0.5
        text: ProtonVpn.connected ? "vpn_key" : "vpn_key_off"
    }
}
