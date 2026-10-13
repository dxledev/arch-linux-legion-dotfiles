import QtQuick
import "../styles"

// A Dashboard task on the selected day. The circle checks it off for that day (kept by Island, not
// in tasks.json); the trash needs a second press, since removing a task removes its whole rule.
Item {
    id: root

    required property var task
    property bool confirming: false

    signal toggled()
    signal removed()

    readonly property string recurrence: {
        if (task.type === "daily") return "Daily"
        if (task.type === "weekly") {
            const days = task.value.split(",").filter(day => day)
            return days.length >= 7 ? "Daily" : "Every " + days.join(", ")
        }
        return "Once"
    }

    width: parent ? parent.width : 0
    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: hover.hovered ? Theme.surfaceVariant : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
    }

    Item {
        id: check
        x: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 26
        height: 26
        Accessible.role: Accessible.CheckBox
        Accessible.name: root.task.task
        Accessible.checked: root.task.done
        Rectangle {
            anchors.centerIn: parent
            width: 18
            height: 18
            radius: 9
            color: root.task.done ? Theme.accent : "transparent"
            border.width: 1.5
            border.color: root.task.done ? Theme.accent : Theme.textMuted
            Behavior on color { ColorAnimation { duration: Theme.animationFast } }
            SvgIcon {
                anchors.centerIn: parent
                source: "../assets/icons/check.svg"
                size: 12
                color: Theme.background
                opacity: root.task.done ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animationFast } }
            }
        }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.toggled() }
    }

    Column {
        anchors.left: check.right
        anchors.leftMargin: 6
        anchors.right: trash.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        UiText {
            width: parent.width
            text: root.task.task
            textFormat: Text.PlainText
            elide: Text.ElideRight
            font.pixelSize: 13
            font.strikeout: root.task.done
            color: root.task.done ? Theme.textMuted : Theme.textPrimary
        }
        UiText {
            width: parent.width
            text: root.recurrence
            elide: Text.ElideRight
            font.pixelSize: 11
            color: Theme.textMuted
        }
    }

    Item {
        id: trash
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: root.confirming ? confirmLabel.implicitWidth + 16 : 28
        height: 26
        opacity: hover.hovered || root.confirming ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animationFast } }
        Behavior on width { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
        Accessible.role: Accessible.Button
        Accessible.name: root.confirming ? "Confirm delete" : "Delete task"
        Rectangle {
            anchors.fill: parent
            radius: 13
            color: root.confirming ? Theme.danger : trashHover.hovered ? Theme.buttonPressed : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.animationFast } }
        }
        SvgIcon {
            anchors.centerIn: parent
            source: "../assets/icons/trash.svg"
            size: 14
            color: Theme.textSecondary
            visible: !root.confirming
        }
        UiText {
            id: confirmLabel
            anchors.centerIn: parent
            visible: root.confirming
            text: "Delete?"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: Theme.background
        }
        HoverHandler { id: trashHover; cursorShape: Qt.PointingHandCursor }
        TapHandler {
            enabled: trash.opacity > 0.5
            onTapped: {
                if (root.confirming) {
                    root.confirming = false
                    root.removed()
                } else {
                    root.confirming = true
                    confirmReset.restart()
                }
            }
        }
    }

    Timer {
        id: confirmReset
        interval: 2500
        onTriggered: root.confirming = false
    }

    HoverHandler { id: hover }
}
