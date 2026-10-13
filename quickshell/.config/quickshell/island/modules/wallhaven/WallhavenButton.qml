import QtQuick
import QtQuick.Controls
import "../../components"
import "../../styles"

// Pill button; `primary` fills it with the accent color.
Button {
    id: root
    property bool primary: false
    property url iconSource
    implicitHeight: 38
    leftPadding: 16
    rightPadding: 16
    hoverEnabled: true
    focusPolicy: Qt.TabFocus
    HoverHandler { enabled: root.enabled && root.hovered; cursorShape: Qt.PointingHandCursor }
    contentItem: Row {
        spacing: 8
        anchors.centerIn: parent
        SvgIcon {
            visible: root.iconSource.toString().length > 0
            anchors.verticalCenter: parent.verticalCenter
            source: root.iconSource
            size: 16
            color: root.primary ? Theme.background : Theme.textPrimary
        }
        UiText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: !root.enabled ? Theme.textMuted : root.primary ? Theme.background : Theme.textPrimary
        }
    }
    background: Rectangle {
        radius: height / 2
        opacity: root.enabled ? 1 : 0.5
        color: root.primary
            ? (root.down ? Theme.accentPressed : root.hovered ? Theme.accentHover : Theme.accent)
            : (root.down ? Theme.buttonPressed : root.hovered ? Theme.surfaceVariant : Theme.buttonBackground)
        border.width: root.activeFocus ? 2 : 0
        border.color: root.primary ? Theme.textPrimary : Theme.accent
        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
    }
}
