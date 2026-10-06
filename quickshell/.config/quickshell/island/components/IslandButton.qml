import QtQuick
import QtQuick.Controls
import "../styles"

Button {
    id: root
    property color backgroundColor: Theme.buttonBackground
    property color textColor: Theme.textPrimary
    property color hoverTextColor: textColor
    property int cursorShape: Qt.ArrowCursor
    implicitHeight: 38
    padding: 10
    contentItem: UiText {
        text: root.text
        color: !root.enabled ? Theme.textMuted : root.hovered ? root.hoverTextColor : root.textColor
        font.pixelSize: 14
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    HoverHandler {
        cursorShape: root.enabled ? root.cursorShape : Qt.ArrowCursor
    }
    background: Rectangle {
        color: root.down ? Theme.buttonPressed : root.hovered ? Theme.buttonHover : root.backgroundColor
        border.color: root.highlighted ? Theme.accent : Theme.borderSubtle
        border.width: root.highlighted || root.activeFocus ? 2 : 1
        radius: height / 2
    }
}
