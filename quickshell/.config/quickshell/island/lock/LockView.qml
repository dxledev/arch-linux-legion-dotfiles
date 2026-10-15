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
    readonly property bool mediaEnabled: ThemeService.settings.lockShowMedia ?? true
    readonly property bool sessionEnabled: ThemeService.settings.lockShowSession ?? true
    // Wide displays put the clock beside the record player; narrow ones stack them, and the player
    // gives way (as before) when the stack would not fit.
    readonly property real gap: 96
    readonly property real leftWidth: Math.min(Math.max(380, clockText.implicitWidth + 8), width - 48)
    readonly property bool wide: width >= leftWidth + media.width + gap + 96
    readonly property bool showMedia: mediaEnabled && (wide ? height >= media.height + 120
        : height >= identity.height + media.height + 40 + 160)
    readonly property bool sideBySide: wide && showMedia
    // The buttons sit under the stage, so they need the room below it and must not meet the battery text.
    readonly property bool showSession: sessionEnabled && width >= 560 && (height - stage.height) / 2 >= session.height + 36
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

    Item {
        id: stage
        anchors.centerIn: parent
        width: root.sideBySide ? root.leftWidth + root.gap + media.width : root.leftWidth
        height: root.sideBySide ? Math.max(identity.height, media.height)
            : identity.height + (root.showMedia ? 40 + media.height : 0)
        opacity: root.entered ? 1 : 0
        scale: root.entered ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: root.animationDuration } }
        Behavior on scale { NumberAnimation { duration: root.animationDuration; easing.type: Easing.OutCubic } }

        Column {
            id: identity
            width: root.leftWidth
            y: root.sideBySide ? (stage.height - height) / 2 : 0
            spacing: 0
            readonly property int textAlign: root.sideBySide ? Text.AlignLeft : Text.AlignHCenter

            Text {
                width: parent.width
                horizontalAlignment: identity.textAlign
                text: "Welcome back, " + root.userName
                color: Theme.textSecondary
                font.family: root.fontFamily
                font.pixelSize: 18
                elide: Text.ElideRight
            }
            Text {
                id: clockText
                objectName: "lock-clock"
                width: parent.width
                horizontalAlignment: identity.textAlign
                text: Qt.formatDateTime(clock.date, ThemeService.settings.clock12Hour ? "h:mm" : "HH:mm")
                color: Theme.textPrimary
                font.family: root.fontFamily
                font.pixelSize: root.clockSize
                font.weight: Font.Light
                font.letterSpacing: -4
            }
            Text {
                objectName: "lock-date"
                width: parent.width
                horizontalAlignment: identity.textAlign
                text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                    + (ThemeService.settings.clock12Hour ? "  ·  " + Qt.formatDateTime(clock.date, "AP") : "")
                color: Theme.textSecondary
                font.family: root.fontFamily
                font.pixelSize: 15
            }
            Item { width: 1; height: 40 }
            LockPassword {
                id: password
                x: root.sideBySide ? 0 : (parent.width - width) / 2
                width: Math.min(340, parent.width)
                auth: root.auth
                fontFamily: root.fontFamily
            }
        }

        LockMedia {
            id: media
            x: root.sideBySide ? root.leftWidth + root.gap : (stage.width - width) / 2
            y: root.sideBySide ? (stage.height - height) / 2 : identity.height + 40
            width: Math.min(440, root.width - 48)
            visible: root.showMedia
            fontFamily: root.fontFamily
            animationDuration: root.animationDuration
            onInteracted: root.focusInput()
        }
    }

    LockSession {
        id: session
        objectName: "lock-session"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        visible: root.showSession
        opacity: root.entered ? 1 : 0
        fontFamily: root.fontFamily
        animationDuration: root.animationDuration
        onInteracted: root.focusInput()
        Behavior on opacity { NumberAnimation { duration: root.animationDuration } }
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
