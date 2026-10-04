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
    
    implicitWidth: 520
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

                iconSource: WifiService.svgIcon

                title: "Wi-Fi"

                subtitle: WifiService.subtitle

                active: WifiService.connected

                onClicked: WifiService.toggle()
            }

            ControlCard {

                iconSource: BluetoothService.icon

                title: "Bluetooth"

                subtitle: BluetoothService.subtitle

                active: BluetoothService.enabled

                onClicked: BluetoothService.toggle()
            }

            ControlCard {

                iconSource: MicrophoneService.icon

                title: "Microphone"

                subtitle: MicrophoneService.subtitle

                active: !MicrophoneService.muted

                onClicked: MicrophoneService.toggle()
            }

            ControlCard {

                objectName: "nightlight-button"
                iconSource: NightLightService.icon

                title: "Night Light"

                subtitle: NightLightService.subtitle

                active: NightLightService.enabled

                onClicked: NightLightService.toggle()
            }

            ControlCard {

                objectName: "idle-lock-button"
                iconSource: IdleLockService.icon

                title: "Idle Lock"

                subtitle: IdleLockService.subtitle

                active: IdleLockService.enabled

                onClicked: IdleLockService.toggle()
            }

            ControlCard {
                iconSource: MediaService.icon

                title: "Media"

                subtitle: MediaService.subtitle

                active: MediaService.hasPlayer

                onClicked: {
                    IslandController.openMediaControls()
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

        Rectangle {

            Layout.fillWidth: true
            Layout.preferredHeight: notificationPreview.implicitHeight + 28

            radius: 26

            color: Theme.surface

            clip: true

            NotificationView {
                id: notificationPreview
                anchors.fill: parent
                anchors.margins: 14
            }
        }
    }
}
