pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components

Item {
    required property color colour

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    MaterialIcon {
        id: icon

        anchors.fill: parent
        text: "psychology"
        color: parent.colour
        fontStyle: Tokens.font.icon.medium
        fill: 1
    }
}
