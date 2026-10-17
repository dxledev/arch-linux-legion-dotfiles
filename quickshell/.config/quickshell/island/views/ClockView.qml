import QtQuick
import Quickshell
import "../components"
import "../styles"
import "../services"

Item {
    id: root

    property bool interactive: true
    property date currentTime: systemClock.date

    implicitWidth: clock.implicitWidth
    implicitHeight: clock.implicitHeight

    // Keyboard: Enter or Space flips between 12 and 24 hour time, like a click.
    activeFocusOnTab: interactive && !ThemeService.busy
    Keys.onReturnPressed: ThemeService.setSetting("clock12Hour", !(ThemeService.settings.clock12Hour ?? false))
    Keys.onEnterPressed: ThemeService.setSetting("clock12Hour", !(ThemeService.settings.clock12Hour ?? false))
    Keys.onSpacePressed: ThemeService.setSetting("clock12Hour", !(ThemeService.settings.clock12Hour ?? false))
    FocusRing { anchors.margins: -4; radius: 8 }

    Text {
        id: clock
        objectName: "clock-label"

        anchors.centerIn: parent
        anchors.alignWhenCentered: false

        color: Theme.textPrimary

        font.family: ThemeService.clockFontFamily
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
