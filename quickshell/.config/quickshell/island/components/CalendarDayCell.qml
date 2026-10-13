import QtQuick
import "../styles"

// One day in the Calendar grid: today is a filled disc, the selection an outlined circle, and up to
// four dots mark what falls on the day.
Item {
    id: root

    required property date cellDate
    property bool inMonth: true
    property bool today: false
    property bool selected: false
    property bool holiday: false
    property var dotColors: []
    property string description: ""

    signal clicked()

    implicitWidth: 56
    implicitHeight: 50
    opacity: inMonth ? 1 : 0.45
    Accessible.role: Accessible.Button
    Accessible.name: description || Qt.formatDate(cellDate, "dddd, MMMM d")

    // Hover, today and the selection all share the day number's circle. Today is a filled disc
    // that becomes an outline while it is selected; any other selected day gets a quieter outline.
    Rectangle {
        id: disc
        width: 30
        height: 30
        radius: 15
        x: (parent.width - width) / 2
        y: 5
        color: root.today && !root.selected ? Theme.accent : hover.hovered && !root.selected ? Theme.surfaceVariant : "transparent"
        border.width: root.selected ? 2 : 0
        border.color: root.today ? Theme.accent : Theme.textSecondary
        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animationFast } }
    }

    UiText {
        x: 0
        y: disc.y
        width: parent.width
        height: disc.height
        text: root.cellDate.getDate()
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 14
        font.weight: root.today || root.holiday ? Font.DemiBold : Font.Normal
        color: root.today ? (root.selected ? Theme.accent : Theme.background) : root.holiday ? Theme.warning : Theme.textPrimary
        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 38
        spacing: 3
        Repeater {
            model: root.dotColors
            Rectangle {
                required property color modelData
                width: 5
                height: 5
                radius: 2.5
                color: modelData
            }
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: root.clicked()
    }
}
