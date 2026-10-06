import QtQuick
import QtQuick.Controls
import "../styles"

Button {
    id: root
    required property string textLabel
    property url iconSource: ""
    width: parent.width
    implicitHeight: 54
    padding: 16
    hoverEnabled: true
    Accessible.name: textLabel
    contentItem: Item {
        SvgIcon {
            id: icon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: root.iconSource.toString().length > 0
            source: root.iconSource
            size: 20
            color: Theme.accent
        }
        UiText {
            anchors.left: parent.left
            anchors.leftMargin: icon.visible ? icon.width + 14 : 0
            anchors.right: arrow.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: root.textLabel
            elide: Text.ElideRight
            color: Theme.textPrimary
            font.pixelSize: 14
        }
        SvgIcon {
            id: arrow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            source: "../assets/icons/chevron-right.svg"
            size: 16
            color: Theme.textSecondary
        }
    }
    background: Rectangle {
        radius: 14
        color: root.down ? Theme.buttonPressed : root.hovered ? Theme.surfaceVariant : Theme.surface
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.accent
    }
}
