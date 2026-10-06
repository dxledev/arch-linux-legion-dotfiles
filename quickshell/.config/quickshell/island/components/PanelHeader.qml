import QtQuick
import QtQuick.Controls
import "../styles"
import "../core"

Item {
    id: root
    required property string title
    property string subtitle: ""
    property string trailingText: ""
    property bool trailingClickable: false
    property var scrollTargets: []
    signal back()
    signal trailingClicked()
    width: parent.width
    implicitHeight: subtitle ? 64 : 48
    IconButton {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        iconSource: "../assets/icons/chevron-left.svg"
        description: "Back"
        onClicked: root.back()
    }
    Column {
        anchors.left: parent.left
        anchors.leftMargin: 52
        anchors.right: trailingLabel.visible ? trailingLabel.left : closeButton.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        UiText {
            id: titleLabel
            objectName: "panel-title"
            width: parent.width
            text: root.title
            color: Theme.textPrimary
            font.pixelSize: 25
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            ScrollProgress {
                anchors.left: parent.left
                anchors.top: parent.bottom
                anchors.topMargin: 1
                width: Math.min(titleLabel.contentWidth, titleLabel.width)
                height: implicitHeight
                scrollTargets: root.scrollTargets
            }
        }
        UiText {
            visible: root.subtitle.length > 0
            text: root.subtitle
            color: Theme.textSecondary
            font.pixelSize: 12
        }
    }
    Button {
        id: trailingLabel
        anchors.right: closeButton.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, Math.max(0, (root.width - 116) / 2))
        visible: root.trailingText.length > 0
        text: root.trailingText
        enabled: root.trailingClickable
        hoverEnabled: root.trailingClickable
        padding: root.trailingClickable ? 10 : 0
        Accessible.name: root.trailingText
        onClicked: root.trailingClicked()
        contentItem: UiText {
            text: trailingLabel.text
            color: root.trailingClickable && (trailingLabel.hovered || trailingLabel.activeFocus) ? Theme.textPrimary : Theme.textSecondary
            font.pixelSize: 13
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            Behavior on color { ColorAnimation { duration: Theme.animationFast } }
        }
        background: Rectangle {
            radius: height / 2
            color: trailingLabel.down ? Theme.buttonPressed : trailingLabel.hovered ? Theme.surfaceVariant : "transparent"
            border.width: root.trailingClickable && trailingLabel.activeFocus ? 2 : 0
            border.color: Theme.accent
            Behavior on color { ColorAnimation { duration: Theme.animationFast } }
        }
        HoverHandler {
            enabled: root.trailingClickable
            cursorShape: Qt.PointingHandCursor
        }
    }
    IconButton {
        id: closeButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        iconSource: "../assets/icons/close.svg"
        description: "Close"
        onClicked: IslandController.reset()
    }
}
