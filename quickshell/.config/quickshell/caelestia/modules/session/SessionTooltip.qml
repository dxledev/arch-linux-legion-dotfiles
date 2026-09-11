import QtQuick
import QtQuick.Controls as Controls
import Caelestia.Config
import qs.components
import qs.services

Controls.ToolTip {
    id: root

    property real panelPadding: 0
    property real gap: Tokens.spacing.medium

    Tokens.screen: parent.Tokens.screen

    x: -width - panelPadding - gap
    y: (parent.height - height) / 2
    delay: 250
    timeout: -1
    horizontalPadding: Tokens.padding.medium
    verticalPadding: Tokens.padding.small

    contentItem: StyledText {
        text: root.text
        color: Colours.palette.m3inverseOnSurface
    }

    background: StyledRect {
        color: Colours.palette.m3inverseSurface
        radius: Tokens.rounding.small
    }
}
