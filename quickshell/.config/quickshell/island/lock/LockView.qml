import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../services"
import "../styles"
import "../components"

FocusScope {
    id: root
    required property LockAuth auth
    property ShellScreen screen: null
    readonly property string fontFamily: ThemeService.settings.lockFontFamily ?? "Noto Sans"
    readonly property int animationDuration: ThemeService.settings.lockAnimationDuration ?? 180
    readonly property string userName: Quickshell.env("USER") || "User"
    readonly property real clockSize: Math.min(ThemeService.settings.lockClockSize ?? 112, width * 0.2)
    property bool entered: false
    property alias passwordField: password

    function focusInput(): void { password.focusInput(); }
    Component.onCompleted: { entered = true; focusInput(); }

    LockBackground {
        objectName: "lock-background"
        anchors.fill: parent
        screen: root.screen
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.focusInput()
    }

    SvgIcon {
        objectName: "lock-indicator"
        anchors.top: parent.top
        anchors.topMargin: 32
        anchors.horizontalCenter: parent.horizontalCenter
        source: "../assets/icons/lock.svg"
        size: 18
        color: Theme.accent
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Column {
        id: content
        anchors.centerIn: parent
        width: Math.min(360, root.width - 48)
        spacing: 0
        opacity: root.entered ? 1 : 0
        scale: root.entered ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: root.animationDuration } }
        Behavior on scale { NumberAnimation { duration: root.animationDuration; easing.type: Easing.OutCubic } }

        Text {
            objectName: "lock-clock"
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, ThemeService.settings.clock12Hour ? "h:mm" : "HH:mm")
            color: Theme.textPrimary
            font.family: root.fontFamily
            font.pixelSize: root.clockSize
            font.weight: Font.Light
            font.letterSpacing: -4
        }
        Text {
            objectName: "lock-date"
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                + (ThemeService.settings.clock12Hour ? "  ·  " + Qt.formatDateTime(clock.date, "AP") : "")
            color: Theme.textSecondary
            font.family: root.fontFamily
            font.pixelSize: 14
        }
        Item { width: 1; height: 48 }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.userName
            color: Theme.textSecondary
            font.family: root.fontFamily
            font.pixelSize: 13
        }
        Item { width: 1; height: 16 }
        LockPassword {
            id: password
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(320, parent.width)
            auth: root.auth
            fontFamily: root.fontFamily
        }
    }

    LockMedia {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 64
        width: Math.min(360, root.width - 48)
        visible: (ThemeService.settings.lockShowMedia ?? true) && MediaService.hasPlayer
            && root.height > content.height + height + 190
        fontFamily: root.fontFamily
    }

    Text {
        objectName: "lock-battery"
        anchors.right: parent.right
        anchors.rightMargin: 32
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        visible: (ThemeService.settings.lockShowBattery ?? true) && UPower.displayDevice.isLaptopBattery
        text: Math.round(UPower.displayDevice.percentage * 100) + "%"
            + (UPower.onBattery ? "" : UPower.displayDevice.state === UPowerDeviceState.Charging ? "  ·  Charging" : "  ·  Plugged in")
        color: Theme.textMuted
        font.family: root.fontFamily
        font.pixelSize: 12
    }
}
