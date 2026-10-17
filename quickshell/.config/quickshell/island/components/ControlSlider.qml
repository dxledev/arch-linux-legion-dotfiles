import QtQuick

import "../styles"

Rectangle {
    id: root

    property string icon: ""
    property url iconSource: ""

    property real value: 0.5

    signal valueChangedByUser(real value)

    implicitWidth: 473
    implicitHeight: 35

    // Left and Right nudge the slider; the ring shows only for keyboard focus.
    property real keyStep: 0.05
    activeFocusOnTab: true
    Keys.onLeftPressed: event => {
        root.valueChangedByUser(Math.max(0, root.value - root.keyStep))
        event.accepted = true
    }
    Keys.onRightPressed: event => {
        root.valueChangedByUser(Math.min(1, root.value + root.keyStep))
        event.accepted = true
    }
    border.width: activeFocus ? 2 : 0
    border.color: Theme.accent

    radius: 20

    color: Theme.surface

    Rectangle {
        width: root.value > 0
            ? Math.max(parent.height, parent.width * root.value)
            : 0

        height: parent.height

        radius: height / 2

        color: Theme.accent
    }

    SvgIcon {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter

        visible: root.iconSource !== ""

        source: root.iconSource

        size: 18

        color: root.value > 0.1 ? Theme.background : Theme.icon
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter

        visible: root.iconSource === ""

        text: root.icon

        font.family: Theme.iconFont
        font.pixelSize: 18

        color: Theme.textPrimary
    }

    MouseArea {
        anchors.fill: parent

        cursorShape: Qt.PointingHandCursor

        onPressed: function(mouse) {
            updateValue(mouse.x)
        }


        onPositionChanged: function(mouse) {

            if (pressed)
                updateValue(mouse.x)

        }


        function updateValue(x) {

            let newValue =
                Math.max(
                    0,
                    Math.min(
                        1,
                        x / root.width
                    )
                )

            root.valueChangedByUser(newValue)
        }
    }
}