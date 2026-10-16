import QtQuick
import "../core"
import "../services"
import "../styles"

// What the island shows in place of the clock while a timer runs: the time in the clock's own type, then a ring
// that drains with the time left. Further timers add a small "+N". The width follows the widest digits, so the
// island does not breathe as the seconds change. With lyrics on, blend goes to 1 and the time fades away,
// leaving the ring.
Item {
    id: root
    objectName: "timer-readout"

    // Clicking opens the timer panel. Off in the compact island, where a click expands it instead.
    property bool interactive: false
    readonly property real fontSize: ThemeService.settings.clockFontSize ?? 18
    readonly property real ringSize: Math.round(fontSize * 0.95)
    // 0 shows the time, the ring and the "+N", 1 only the ring.
    property real blend: 0
    readonly property alias ring: ring
    readonly property alias label: label
    readonly property real labelWidth: Math.ceil(Math.max(widest.advanceWidth, label.implicitWidth))
    // Width with only the ring, and with everything: what the island makes room for in each case.
    readonly property real ringWidth: ringSize
    readonly property real fullWidth: labelWidth + row.spacing + ringSize + (TimerService.others > 0 ? row.spacing + others.implicitWidth : 0)

    implicitWidth: row.implicitWidth
    implicitHeight: Math.max(label.implicitHeight, ringSize)
    Accessible.role: Accessible.Button
    Accessible.name: "Timer, " + TimerService.leadingText + (TimerService.leadingPaused ? " left, paused" : " left")
    Accessible.onPressAction: IslandController.openTimer()

    Row {
        id: row
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: label
            objectName: "timer-label"
            anchors.verticalCenter: parent.verticalCenter
            width: root.labelWidth * (1 - root.blend)
            opacity: 1 - root.blend
            visible: root.blend < 1
            clip: true
            horizontalAlignment: Text.AlignHCenter
            color: TimerService.leadingPaused ? Theme.textSecondary : TimerService.leadingUrgent ? Theme.warning : Theme.textPrimary
            font.family: ThemeService.clockFontFamily
            font.pixelSize: root.fontSize
            font.bold: ThemeService.settings.clockFontBold ?? true
            text: TimerService.leadingText
            Behavior on color { ColorAnimation { duration: Theme.animationNormal } }
        }

        CountdownRing {
            id: ring
            objectName: "timer-ring"
            anchors.verticalCenter: parent.verticalCenter
            width: root.ringSize
            height: root.ringSize
            thickness: Math.max(2, Math.round(root.ringSize / 7))
            progress: TimerService.leadingProgress
            ringColor: TimerService.leadingPaused ? Theme.textSecondary : TimerService.leadingUrgent ? Theme.warning : Theme.accent
            Behavior on ringColor { ColorAnimation { duration: Theme.animationNormal } }
            Behavior on progress { NumberAnimation { duration: 250; easing.type: Easing.Linear } }
        }

        Text {
            id: others
            objectName: "timer-others"
            anchors.verticalCenter: parent.verticalCenter
            visible: TimerService.others > 0 && root.blend < 1
            opacity: 1 - root.blend
            color: Theme.textSecondary
            font.family: ThemeService.clockFontFamily
            font.pixelSize: Math.round(root.fontSize * 0.65)
            font.bold: true
            text: "+" + TimerService.others
        }
    }

    TextMetrics {
        id: widest
        font: label.font
        text: TimerService.leadingText.length > 5 ? "0:00:00" : "00:00"
    }

    MouseArea {
        objectName: "timer-readout-open"
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: IslandController.openTimer()
    }
}
