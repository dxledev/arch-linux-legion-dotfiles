import "../effects"
import QtQuick
import QtQuick.Templates
import Caelestia.Config
import qs.components
import qs.services

Slider {
    id: root

    required property string icon
    property int valueDisplayDuration: 1500
    property bool showInitialValue: false
    property real oldValue
    property bool initialized

    signal rightClicked()

    orientation: Qt.Vertical

    background: StyledRect {
        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
        radius: Tokens.rounding.full

        StyledRect {
            anchors.left: parent.left
            anchors.right: parent.right

            y: root.handle.y
            implicitHeight: parent.height - y

            color: Colours.palette.m3secondary
            radius: parent.radius
        }
    }

    handle: Item {
        id: handle

        property alias moving: icon.moving

        y: root.visualPosition * (root.availableHeight - height)
        implicitWidth: root.width
        implicitHeight: root.width

        Elevation {
            anchors.fill: parent
            radius: rect.radius
            level: handleInteraction.containsMouse ? 2 : 1
        }

        StyledRect {
            id: rect

            anchors.fill: parent

            color: Colours.palette.m3inverseSurface
            radius: Tokens.rounding.full

            MouseArea {
                id: handleInteraction

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.NoButton
            }

            MaterialIcon {
                id: icon

                property bool moving

                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                text: moving ? Math.round(root.value * 100) : root.icon
                color: Colours.palette.m3inverseOnSurface
                font: moving ? Tokens.font.body.small : Tokens.font.icon.medium

                Behavior on moving {
                    enabled: root.initialized

                    SequentialAnimation {
                        Anim {
                            target: icon
                            property: "scale"
                            to: 0.3
                            duration: Tokens.anim.durations.small / 2
                            easing: Tokens.anim.standardAccel
                        }
                        PropertyAction {}
                        Anim {
                            target: icon
                            property: "scale"
                            to: 1
                            duration: Tokens.anim.durations.normal / 2
                            easing: Tokens.anim.standardDecel
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons & ~Qt.LeftButton
        preventStealing: true
        onClicked: event => {
            if (event.button === Qt.RightButton)
                root.rightClicked();
        }
    }

    onPressedChanged: {
        if (pressed) {
            stateChangeDelay.stop();
            handle.moving = true;
        } else {
            stateChangeDelay.restart();
        }
    }

    Component.onCompleted: {
        oldValue = value;
        handle.moving = showInitialValue;
        initialized = true;
        if (showInitialValue)
            stateChangeDelay.restart();
    }

    onValueChanged: {
        if (!initialized || Math.round(value * 100) === Math.round(oldValue * 100))
            return;
        oldValue = value;
        handle.moving = true;
        stateChangeDelay.restart();
    }

    Timer {
        id: stateChangeDelay

        interval: root.valueDisplayDuration
        onTriggered: {
            if (!root.pressed)
                handle.moving = false;
        }
    }

    Behavior on value {
        enabled: !root.pressed

        Anim {
            type: Anim.StandardLarge
        }
    }
}
