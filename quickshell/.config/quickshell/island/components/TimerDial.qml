import QtQuick
import "../services/TimerLogic.js" as TimerLogic
import "../styles"

// A kitchen timer's face. The wedge is the time dialed in, a full turn being an hour; the knob at its end is
// dragged to turn the dial by whole minutes. Typing and the preset buttons live in the panel around it.
Item {
    id: root
    objectName: "timer-dial"

    property int seconds: 0
    readonly property real thickness: 10
    readonly property real fill: TimerLogic.dialFill(seconds)
    readonly property bool dragging: mouse.pressed && mouse.turning
    signal minutesPicked(int minutes)

    implicitWidth: 184
    implicitHeight: 184
    Accessible.role: Accessible.Slider
    Accessible.name: "Timer length"
    Accessible.description: TimerLogic.describe(seconds)

    Repeater {
        model: 12
        Item {
            required property int index
            anchors.fill: parent
            rotation: index * 30
            Rectangle {
                x: parent.width / 2 - width / 2
                y: root.thickness + 8
                width: 2
                height: index % 3 === 0 ? 9 : 5
                radius: 1
                color: Theme.textMuted
                opacity: 0.8
            }
        }
    }

    CountdownRing {
        id: ring
        objectName: "timer-dial-ring"
        anchors.fill: parent
        thickness: root.thickness
        progress: root.fill
        trackColor: Theme.surfaceVariant
        ringColor: Theme.accent
        Behavior on progress {
            enabled: !root.dragging
            NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic }
        }
    }

    // The knob rides the end of the wedge, and rests at 12 o'clock when nothing is dialed.
    Rectangle {
        id: knob
        objectName: "timer-dial-knob"
        readonly property real angle: (ring.progress * 360 - 90) * Math.PI / 180
        width: 20
        height: 20
        radius: 10
        x: root.width / 2 + ring.ringRadius * Math.cos(angle) - width / 2
        y: root.height / 2 + ring.ringRadius * Math.sin(angle) - height / 2
        color: Theme.accent
        border.width: 4
        border.color: Theme.background
        scale: mouse.pressed ? 1.15 : mouse.containsMouse ? 1.08 : 1
        Behavior on scale { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
    }

    Column {
        anchors.centerIn: parent
        spacing: 4
        UiText {
            objectName: "timer-dial-time"
            anchors.horizontalCenter: parent.horizontalCenter
            text: TimerLogic.formatClock(root.seconds)
            color: root.seconds > 0 ? Theme.textPrimary : Theme.textMuted
            font.pixelSize: 38
            font.weight: Font.DemiBold
        }
        UiText {
            objectName: "timer-dial-hint"
            anchors.horizontalCenter: parent.horizontalCenter
            width: 112
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            visible: root.seconds === 0
            text: "Type a time or turn the dial"
            color: Theme.textMuted
            font.pixelSize: 12
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        // Only the ring turns the dial; the face in the middle is left for the digits.
        property bool turning: false
        hoverEnabled: true
        cursorShape: turning || onRing(mouseX, mouseY) ? Qt.PointingHandCursor : Qt.ArrowCursor

        function onRing(x, y) {
            return Math.hypot(x - width / 2, y - height / 2) > width * 0.26
        }

        function pick(x, y, previous) {
            const angle = TimerLogic.angleAt(x - width / 2, y - height / 2)
            root.minutesPicked(TimerLogic.dialMinutesAt(angle, previous))
        }

        onPressed: event => {
            root.forceActiveFocus()
            turning = onRing(event.x, event.y)
            if (turning) pick(event.x, event.y, undefined)
        }
        onPositionChanged: event => {
            if (pressed && turning) pick(event.x, event.y, Math.round(root.seconds / 60))
        }
        onReleased: turning = false
        onCanceled: turning = false
    }
}
