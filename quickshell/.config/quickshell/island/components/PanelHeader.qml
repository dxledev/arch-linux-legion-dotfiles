import QtQuick
import "../styles"
import "../core"

Item {
    id: root
    required property string title
    property string subtitle: ""
    property string trailingText: ""
    property var scrollTargets: []
    signal back()
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
        Text {
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
        Text {
            visible: root.subtitle.length > 0
            text: root.subtitle
            color: Theme.textSecondary
            font.pixelSize: 12
        }
    }
    Text {
        id: trailingLabel
        anchors.right: closeButton.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, Math.max(0, (root.width - 116) / 2))
        visible: root.trailingText.length > 0
        text: root.trailingText
        color: Theme.textSecondary
        font.pixelSize: 13
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
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
