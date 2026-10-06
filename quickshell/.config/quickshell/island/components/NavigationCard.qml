import QtQuick
import QtQuick.Controls
import "../styles"

Button {
    id: root
    required property string title
    property string subtitle: ""
    required property url iconSource
    implicitHeight: 132
    padding: 18
    hoverEnabled: true
    Accessible.name: title
    background: Rectangle {
        radius: 26
        color: root.down ? Theme.buttonPressed : root.hovered ? Theme.surfaceVariant : Theme.surface
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.accent
        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
    }
    contentItem: Item {
        Rectangle {
            width: 40
            height: 40
            radius: 20
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
            SvgIcon { anchors.centerIn: parent; source: root.iconSource; color: Theme.accent; size: 22 }
        }
        SvgIcon {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 12
            source: "../assets/icons/chevron-right.svg"
            color: Theme.textMuted
            size: 16
        }
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 4
            UiText { text: root.title; color: Theme.textPrimary; font.pixelSize: 15; font.weight: Font.DemiBold }
            UiText { width: parent.width; text: root.subtitle; color: Theme.textSecondary; font.pixelSize: 11; elide: Text.ElideRight }
        }
    }
}
