import QtQuick
import QtQuick.Controls as Controls
import Caelestia.Config
import qs.components
import qs.services

Controls.ToolTip {
    id: root

    property bool onLeft: true

    Tokens.screen: parent.Tokens.screen
    x: onLeft ? -width - Tokens.padding.large : (parent.width - width) / 2
    y: onLeft ? (parent.height - height) / 2 : parent.height + Tokens.padding.medium
    delay: 250
    timeout: -1

    contentItem: StyledText {
        text: root.text
        color: Colours.palette.m3inverseOnSurface
    }

    background: StyledRect {
        color: Colours.palette.m3inverseSurface
        radius: Tokens.rounding.small
    }
}
