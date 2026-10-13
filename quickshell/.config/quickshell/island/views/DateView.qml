import QtQuick
import "../styles"
import "../services"
import "../core"

Text {
    id: date

    // Set by the expanded island: clicking the date opens the Calendar.
    property bool interactive: false

    color: interactive && mouse.containsMouse ? Theme.textPrimary : Theme.textSecondary

    font.family: ThemeService.clockFontFamily
    font.pixelSize: 11

    text: Qt.formatDate(new Date(), "ddd, MMM d")

    Behavior on color { ColorAnimation { duration: Theme.animationFast } }

    Timer {
        interval: 60000
        running: true
        repeat: true

        onTriggered: {
            date.text = Qt.formatDate(new Date(), "ddd, MMM d")
        }
    }

    MouseArea {
        id: mouse
        objectName: "date-calendar-button"
        anchors.fill: parent
        anchors.leftMargin: -8
        anchors.rightMargin: -8
        anchors.topMargin: -2
        anchors.bottomMargin: -4
        enabled: date.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: "Open calendar"
        onClicked: {
            IslandController.ignoreNextIslandTap()
            IslandController.openCalendar()
        }
    }
}
