import QtQuick
import Quickshell
import "../styles"
import "../services"

Item {
    id: root

    property bool interactive: true
    property date currentTime: systemClock.date

    implicitWidth: clock.implicitWidth
    implicitHeight: clock.implicitHeight

    Text {
        id: clock
        objectName: "clock-label"

        anchors.centerIn: parent

        color: Theme.textPrimary

        font.family: ThemeService.settings.clockFontFamily || "JetBrainsMono Nerd Font"
        font.pixelSize: ThemeService.settings.clockFontSize ?? 18
        font.bold: ThemeService.settings.clockFontBold ?? true

        text: Qt.formatTime(root.currentTime, (ThemeService.settings.clock12Hour ?? false) ? "h:mm AP" : "HH:mm")
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    MouseArea {
        objectName: "clock-format-button"
        anchors.fill: parent
        enabled: root.interactive && !ThemeService.busy
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: ThemeService.setSetting("clock12Hour", !(ThemeService.settings.clock12Hour ?? false))
    }
}
