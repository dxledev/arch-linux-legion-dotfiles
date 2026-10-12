import QtQuick
import QtQuick.Controls
import "../styles"

Button {
    id: root
    property bool danger: false

    implicitHeight: 28
    padding: 10
    hoverEnabled: true
    focusPolicy: Qt.TabFocus

    HoverHandler {
        enabled: root.enabled && root.hovered
        cursorShape: Qt.PointingHandCursor
    }

    contentItem: UiText {
        text: root.text
        font.pixelSize: 12
        color: !root.enabled ? Theme.textMuted : root.danger ? Theme.danger : Theme.textPrimary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: height / 2
        color: root.down ? Theme.buttonPressed : root.hovered ? Theme.surfaceVariant : Theme.buttonBackground
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.accent
        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
    }
}
