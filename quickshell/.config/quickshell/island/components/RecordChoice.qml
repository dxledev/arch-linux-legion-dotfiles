import QtQuick
import QtQuick.Controls
import "../styles"

// A pill for the recording popup: one of three capture modes, or a switch (webcam, sound) when `checkable`.
Button {
    id: root
    property url iconSource
    property bool selected: false
    property string detail: ""
    implicitHeight: 44
    leftPadding: 14
    rightPadding: 14
    hoverEnabled: true
    focusPolicy: Qt.TabFocus
    opacity: enabled ? 1 : 0.45
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.checked: selected
    HoverHandler {
        enabled: root.enabled && root.hovered
        cursorShape: Qt.PointingHandCursor
    }
    contentItem: Row {
        spacing: 10
        SvgIcon {
            anchors.verticalCenter: parent.verticalCenter
            source: root.iconSource
            size: 18
            color: root.selected ? Theme.background : Theme.textSecondary
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            UiText {
                text: root.text
                color: root.selected ? Theme.background : Theme.textPrimary
                font.pixelSize: 14
                font.weight: Font.Medium
            }
            UiText {
                visible: root.detail.length > 0
                text: root.detail
                color: root.selected ? Qt.alpha(Theme.background, 0.7) : Theme.textMuted
                font.pixelSize: 11
            }
        }
    }
    background: Rectangle {
        radius: 16
        color: root.selected ? Theme.accent : root.down ? Theme.buttonPressed : root.hovered ? Theme.surfaceVariant : Theme.surface
        border.width: root.activeFocus ? 2 : 0
        border.color: root.selected ? Theme.textPrimary : Theme.accent
        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
    }
}
