import QtQuick
import QtQuick.Templates
import Caelestia.Config
import qs.components
import qs.services

RadioButton {
    id: root

    font: Tokens.font.body.small
    readonly property bool unavailable: !enabled

    implicitWidth: implicitIndicatorWidth + implicitContentWidth + contentItem.anchors.leftMargin
    implicitHeight: Math.max(implicitIndicatorHeight, implicitContentHeight)

    indicator: Rectangle {
        id: outerCircle

        implicitWidth: 20
        implicitHeight: 20
        radius: Tokens.rounding.full
        color: "transparent"
        border.color: Colours.foreground(root.checked ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant, outerCircle, root.unavailable)
        border.width: 2
        anchors.verticalCenter: parent.verticalCenter

        StateLayer {
            anchors.margins: -Tokens.padding.small
            color: root.checked ? Colours.palette.m3onSurface : Colours.palette.m3primary
            z: -1
            onClicked: root.click()
        }

        StyledRect {
            anchors.centerIn: parent
            implicitWidth: 8
            implicitHeight: 8

            radius: Tokens.rounding.full
            color: root.checked ? Colours.foreground(Colours.palette.m3primary, outerCircle, root.unavailable) : Qt.alpha(Colours.palette.m3primary, 0)
        }

        Behavior on border.color {
            CAnim {}
        }
    }

    contentItem: StyledText {
        text: root.text
        font: root.font
        color: Colours.foreground(Colours.palette.m3onSurface, root, root.unavailable)
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: outerCircle.right
        anchors.right: parent.right
        anchors.leftMargin: Tokens.spacing.medium
        elide: Text.ElideRight
    }
}
