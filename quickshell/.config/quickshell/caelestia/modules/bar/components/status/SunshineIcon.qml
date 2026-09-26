pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components

MaterialIcon {
    required property color colour

    text: "cast_connected"
    color: colour
    fontStyle: Tokens.font.icon.small
    fill: 1
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
