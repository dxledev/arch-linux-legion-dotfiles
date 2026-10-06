import QtQuick

import "../components"
import "../services"
import "../core"

FocusScope {
    id: root

    property int selectedIndex: 3
    property bool keyboardSelection: false
    property int horizontalPadding: 24

    implicitWidth: options.implicitWidth + horizontalPadding * 2
    implicitHeight: 75

    Component.onCompleted: {
        forceActiveFocus()
    }

    Keys.onPressed: function(event) {

        switch (event.key) {

        case Qt.Key_Left:
        case Qt.Key_H:

            selectedIndex = (selectedIndex + 4) % 5
            keyboardSelection = true
            event.accepted = true
            break

        case Qt.Key_Right:
        case Qt.Key_L:

            selectedIndex = (selectedIndex + 1) % 5
            keyboardSelection = true
            event.accepted = true
            break

        case Qt.Key_Return:
        case Qt.Key_Enter:

            switch (selectedIndex) {

            case 0:
                PowerService.poweroff()
                break

            case 1:
                PowerService.reboot()
                break

            case 2:
                NightLightService.toggle()
                break

            case 3:
                PowerService.lock()
                break

            case 4:
                IslandController.openSystem()
                break
            }

            event.accepted = true
            break

        case Qt.Key_Escape:

            IslandController.reset()

            event.accepted = true
            break
        }
    }

    Row {
        id: options
        anchors.centerIn: parent
        spacing: 8

        PowerOption {
            selected: root.keyboardSelection && root.selectedIndex === 0

            icon: ""
            title: "Power"
            action: PowerService.poweroff
        }

        PowerOption {
            selected: root.keyboardSelection && root.selectedIndex === 1

            icon: "󰑐"
            title: "Reboot"
            action: PowerService.reboot
        }

        PowerOption {
            selected: root.keyboardSelection && root.selectedIndex === 2

            objectName: "session-nightlight-button"
            icon: "󰖔"
            title: "Nightlight"
            active: NightLightService.enabled
            action: NightLightService.toggle
        }

        PowerOption {
            selected: root.keyboardSelection && root.selectedIndex === 3

            icon: "󰌾"
            title: "Lock"
            action: PowerService.lock
        }

        PowerOption {
            selected: root.keyboardSelection && root.selectedIndex === 4

            icon: "󰍹"
            title: "System"
            action: IslandController.openSystem
        }
    }
}
