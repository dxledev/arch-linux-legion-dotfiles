import QtQuick
import QtQuick.Controls
import "../styles"

ToolTip {
    id: root

    delay: 700
    padding: 10
    leftPadding: 14
    rightPadding: 14
    popupType: Popup.Window

    contentItem: Text {
        text: root.text
        textFormat: Text.PlainText
        color: Theme.textPrimary
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        color: Theme.background
        radius: height / 2
        border.width: 1
        border.color: Theme.surfaceVariant
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animationFast }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animationFast }
    }
}
