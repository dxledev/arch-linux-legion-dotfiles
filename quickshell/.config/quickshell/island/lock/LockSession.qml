pragma ComponentBehavior: Bound
import QtQuick
import "../services"
import "../styles"
import "../components"

// The session buttons from the power panel (SUPER+ALT+P) that still make sense on a locked screen:
// Shutdown, Reboot and Nightlight. Lock (already locked) and System (an Island panel, which cannot
// open over the lock) are left out. The panel confirms through the status drawer, which the lock
// surface does not show, so Shutdown and Reboot ask inline: the first click arms the button, the
// second one acts, and it disarms itself after a few seconds.
Row {
    id: root
    property string fontFamily: "Noto Sans"
    property int animationDuration: 180
    // Name of the destructive button waiting for its second click, or "".
    property string armed: ""
    signal interacted()

    spacing: 10

    Timer {
        id: disarm
        interval: 3500
        onTriggered: root.armed = ""
    }

    function press(key, confirm, action): void {
        root.interacted();
        if (confirm && root.armed !== key) {
            root.armed = key;
            disarm.restart();
            return;
        }
        root.armed = "";
        disarm.stop();
        action();
    }

    Repeater {
        model: [{
            key: "shutdown",
            title: "Shutdown",
            icon: "../assets/icons/power.svg",
            confirm: true
        }, {
            key: "reboot",
            title: "Reboot",
            icon: "../assets/icons/refresh.svg",
            confirm: true
        }, {
            key: "nightlight",
            title: "Nightlight",
            icon: "../assets/icons/moon.svg",
            confirm: false
        }]

        delegate: Rectangle {
            id: button
            required property var modelData
            readonly property bool active: modelData.key === "nightlight" && NightLightService.enabled
            readonly property bool confirming: root.armed === modelData.key
            readonly property color content: confirming ? Theme.danger : active ? Theme.background : Theme.textPrimary

            objectName: "lock-session-" + modelData.key
            width: 88
            height: 64
            radius: 20
            color: confirming ? Qt.alpha(Theme.danger, 0.18)
                : active ? (tap.pressed ? Theme.accentPressed : hover.hovered ? Theme.accentHover : Theme.accent)
                : tap.pressed ? Qt.alpha(Theme.surfaceVariant, 0.96)
                : hover.hovered ? Qt.alpha(Theme.surfaceVariant, 0.9)
                : Qt.alpha(Theme.surface, 0.84)
            border.width: 1
            border.color: confirming ? Theme.danger : Qt.alpha(Theme.textPrimary, 0.08)
            scale: hover.hovered ? 1.04 : 1
            Behavior on color { ColorAnimation { duration: root.animationDuration * 0.7 } }
            Behavior on border.color { ColorAnimation { duration: root.animationDuration * 0.7 } }
            Behavior on scale { NumberAnimation { duration: root.animationDuration * 0.7; easing.type: Easing.OutCubic } }

            Accessible.role: Accessible.Button
            Accessible.name: confirming ? "Confirm " + modelData.title.toLowerCase() : modelData.title

            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                id: tap
                acceptedButtons: Qt.LeftButton
                onTapped: {
                    switch (button.modelData.key) {
                    case "shutdown": root.press("shutdown", true, PowerService.poweroff); break;
                    case "reboot": root.press("reboot", true, PowerService.reboot); break;
                    default: root.press("nightlight", false, NightLightService.toggle);
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                width: parent.width - 8
                spacing: 6

                Item {
                    width: parent.width
                    height: 20
                    SvgIcon {
                        anchors.centerIn: parent
                        source: button.active ? "../assets/icons/moon-stars.svg" : button.modelData.icon
                        size: 20
                        color: button.content
                    }
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: button.confirming ? "Confirm?" : button.modelData.title
                    color: button.content
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.bold: button.confirming
                    elide: Text.ElideRight
                }
            }
        }
    }
}
