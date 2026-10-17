import QtQuick
import QtQuick.Layouts

import "../styles"
import "../components"
import "../core"
import "../views"
import "../services"

Item {
    id: root

    clip: true
    
    // Wide enough for the last row: Sunshine (with its open button), Timer and Do Not Disturb in a wide UI font.
    implicitWidth: 630
    implicitHeight: content.implicitHeight + 44

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 22

        spacing: 18

        PanelHeader {
            title: "Control Center"
            scrollTargets: [brightnessControls]
            Layout.fillWidth: true
            onBack: IslandController.openExpanded()
        }

        GridLayout {
            Layout.fillWidth: true

            columns: 3

            columnSpacing: 12
            rowSpacing: 12

            ControlCard {
                Layout.fillWidth: true
                objectName: "wifi-control-card"
                iconSource: WifiService.svgIcon

                title: "Wi-Fi"

                subtitle: WifiService.subtitle

                active: WifiService.connected
                iconEnabled: true
                panelEnabled: true
                onIconToggled: WifiService.toggle()
                onClicked: IslandController.openWifi()
            }

            ControlCard {
                Layout.fillWidth: true
                objectName: "bluetooth-control-card"
                iconSource: BluetoothService.icon

                title: "Bluetooth"

                subtitle: BluetoothService.subtitle

                active: BluetoothService.enabled
                iconEnabled: true
                panelEnabled: true
                onIconToggled: BluetoothService.toggle()
                onClicked: IslandController.openBluetooth()
            }

            ControlCard {
                Layout.fillWidth: true
                objectName: "microphone-control-card"
                iconSource: MicrophoneService.icon

                title: "Microphone"

                subtitle: MicrophoneService.subtitle

                active: !MicrophoneService.muted
                iconEnabled: true
                panelEnabled: true
                onIconToggled: MicrophoneService.toggle()
                onClicked: IslandController.openAudioDevices()
            }

            ControlCard {
                Layout.fillWidth: true

                objectName: "nightlight-button"
                visible: NightLightService.available
                iconSource: NightLightService.icon

                title: "Night Light"

                subtitle: NightLightService.subtitle

                active: NightLightService.enabled
                iconEnabled: true
                panelEnabled: false
                onIconToggled: NightLightService.toggle()
            }

            ControlCard {
                Layout.fillWidth: true

                objectName: "idle-lock-button"
                iconSource: IdleLockService.icon

                title: "Idle Lock"

                subtitle: IdleLockService.subtitle

                active: IdleLockService.enabled
                iconEnabled: true
                panelEnabled: false
                onIconToggled: IdleLockService.toggle()
            }

            ControlCard {
                Layout.fillWidth: true
                objectName: "media-control-card"
                iconSource: Qt.resolvedUrl(MediaService.isPlaying
                    ? "../assets/icons/player-play.svg"
                    : "../assets/icons/player-pause.svg")

                title: "Media"

                subtitle: MediaService.subtitle

                active: MediaService.isPlaying
                iconEnabled: MediaService.canTogglePlayback
                panelEnabled: true
                onIconToggled: MediaService.togglePlayback()
                onClicked: IslandController.openMediaControls()
            }

            // Sunshine, the timer and the notification button share the last row evenly, as wide as the cards above.
            RowLayout {
                Layout.fillWidth: true
                Layout.columnSpan: 3
                spacing: 12

                ControlCard {
                    Layout.fillWidth: true
                    // The last row's cards are the same width as each other and as the cards above.
                    Layout.preferredWidth: 1
                    objectName: "sunshine-control-card"
                    iconSource: SunshineService.icon

                    title: "Sunshine"

                    subtitle: SunshineService.subtitle

                    active: SunshineService.running
                    iconEnabled: !SunshineService.busy
                    panelEnabled: !SunshineService.busy
                    trailingIconSource: Qt.resolvedUrl("../assets/icons/external-link.svg")
                    trailingLabel: "Open Sunshine web UI"
                    onIconToggled: SunshineService.toggle()
                    onClicked: SunshineService.toggle()
                    onTrailingClicked: {
                        SunshineService.openWebUi();
                        IslandController.reset();
                    }
                }

                // A clock until a timer runs; then the icon lights up with a ring that drains with the time left, and
                // pressing it pauses the timers (or resumes them). The rest of the card opens the timer panel.
                ControlCard {
                    Layout.fillWidth: true
                    objectName: "timer-control-card"
                    Layout.preferredWidth: 1
                    iconSource: Qt.resolvedUrl(TimerService.leadingPaused
                        ? "../assets/icons/player-pause.svg"
                        : "../assets/icons/clock.svg")

                    title: TimerService.active ? "Active Timer" : "Timer"

                    subtitle: !TimerService.active ? "Off"
                        : TimerService.leadingPaused ? TimerService.leadingText + " paused" : TimerService.leadingText

                    active: TimerService.active
                    progress: TimerService.active ? TimerService.leadingProgress : -1
                    iconEnabled: true
                    panelEnabled: true
                    onIconToggled: TimerService.active ? TimerService.toggleAllPaused() : IslandController.openTimer()
                    onClicked: IslandController.openTimer()
                }

                ControlCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    objectName: "notifications-button"
                    iconSource: Qt.resolvedUrl(NotificationService.doNotDisturb
                        ? "../assets/icons/bell-off.svg"
                        : "../assets/icons/bell.svg")

                    title: NotificationService.doNotDisturb ? "Do Not Disturb" : "Alerts"

                    subtitle: NotificationService.doNotDisturb ? "Silent mode on" : NotificationService.countText

                    active: NotificationService.doNotDisturb
                    iconEnabled: true
                    panelEnabled: true
                    onIconToggled: NotificationService.toggleDoNotDisturb()
                    onClicked: IslandController.openNotifications()
                }
            }
        }

        AudioControls {
            Layout.fillWidth: true
        }

        BrightnessControls {
            id: brightnessControls
            Layout.fillWidth: true
        }
    }
}
