pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

MouseArea {
    id: root

    required property color colour

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight
    cursorShape: Qt.PointingHandCursor

    onClicked: Sunshine.toggle()

    MaterialIcon {
        id: icon

        anchors.fill: parent
        animate: true
        text: Sunshine.state === "running" ? "cast_connected" : "cast"
        color: root.colour
        fontStyle: Tokens.font.icon.small
        fill: 1
    }
}
