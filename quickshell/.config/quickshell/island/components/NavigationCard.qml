import QtQuick
import QtQuick.Controls
import "../styles"

Button {
    id: root
    required property string title
    property string subtitle: ""
    required property url iconSource
    property bool showPin: false
    property bool pinned: false
    property bool pinEnabled: true
    property bool selected: false
    signal pinClicked()
    implicitHeight: 132
    padding: 18
    hoverEnabled: true
    Accessible.name: title
    background: Rectangle {
        radius: 26
        color: root.down ? Theme.buttonPressed : root.hovered ? Theme.surfaceVariant : Theme.surface
        border.width: root.activeFocus || root.selected ? 2 : 0
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
            id: chevron
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 12
            source: "../assets/icons/chevron-right.svg"
            color: Theme.textMuted
            size: 16
        }
        IconButton {
            objectName: "navigation-card-pin"
            anchors.right: chevron.left
            anchors.rightMargin: 4
            anchors.top: parent.top
            anchors.topMargin: 4
            width: 32
            height: 32
            padding: 7
            visible: root.showPin
            enabled: root.pinEnabled
            opacity: enabled ? 1 : 0.4
            iconSource: root.pinned ? "../assets/icons/pin-filled.svg" : "../assets/icons/pin.svg"
            iconColor: root.pinned ? Theme.accent : Theme.textSecondary
            description: root.pinned ? "Unpin " + root.title : root.pinEnabled ? "Pin " + root.title : "Unpin a submenu first"
            Accessible.checkable: true
            Accessible.checked: root.pinned
            onClicked: root.pinClicked()
        }
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 4
            UiText { width: parent.width; text: root.title; color: Theme.textPrimary; font.pixelSize: 15; font.weight: Font.DemiBold; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight }
            UiText { width: parent.width; text: root.subtitle; color: Theme.textSecondary; font.pixelSize: 11; elide: Text.ElideRight }
        }
    }
}
