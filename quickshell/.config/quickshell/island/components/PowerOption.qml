import QtQuick
import "../styles"

Rectangle {
    id: root

    property bool selected: false
    property bool active: false

    property string icon: ""
    property string title: ""

    property var action

    width: 93
    height: 58

    radius: 18

    color: tap.pressed ? (active ? Theme.accentPressed : Theme.buttonPressed)
        : hover.hovered ? (active ? Theme.accentHover : Theme.buttonHover)
        : active ? Theme.accent : Theme.buttonBackground
    border.width: selected && !active ? 2 : 0
    border.color: Theme.accent

    scale: hover.hovered ? 1.04 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 130
            easing.type: Easing.OutCubic
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: 130
        }
    }

    // Toggled-on buttons are already accent-filled, so draw the keyboard
    // selection as an inset ring in the on-accent color instead.
    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: root.radius - 3
        color: "transparent"
        border.width: 2
        border.color: Theme.background
        visible: root.selected && root.active
    }

    HoverHandler { id: hover }

    TapHandler {
        id: tap
        acceptedButtons: Qt.LeftButton

        onTapped: {
            if (root.action)
                root.action()
        }
    }


    Column {
        anchors.centerIn: parent

        spacing: 2

        enabled: false

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: root.icon

            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20

            color: root.active ? Theme.background : Theme.textPrimary
        }

        UiText {
            anchors.horizontalCenter: parent.horizontalCenter

            text: root.title

            font.pixelSize: 11

            color: root.active ? Theme.background : Theme.textPrimary
        }
    }
}
