import QtQuick

import "../components"
import "../services"
import "../core"
import "../island"

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

    // Shutdown and reboot are destructive, so they ask first via the status drawer
    // (same card as the wallpaper delete confirmation).
    property bool askedPower: false

    function confirmPower(title, detail, acceptLabel, handler) {
        if (StatusManager.confirming) StatusManager.resolveConfirm(false)
        askedPower = true
        StatusManager.confirm({
            monitorName: IslandState.panelMonitorName,
            title: title,
            detail: detail,
            acceptLabel: acceptLabel,
            onAccepted: function() {
                root.askedPower = false
                handler()
            }
        })
    }

    function requestPoweroff() {
        confirmPower("Shut down?", "Unsaved work in open apps will be lost.", "Shutdown", PowerService.poweroff)
    }

    function requestReboot() {
        confirmPower("Reboot?", "Unsaved work in open apps will be lost.", "Reboot", PowerService.reboot)
    }

    Component.onDestruction: {
        if (askedPower && StatusManager.confirming) StatusManager.resolveConfirm(false)
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
                requestPoweroff()
                break

            case 1:
                requestReboot()
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

            if (StatusManager.confirming) {
                askedPower = false
                StatusManager.resolveConfirm(false)
            } else IslandController.reset()

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
            objectName: "session-shutdown-button"
            title: "Shutdown"
            action: root.requestPoweroff
        }

        PowerOption {
            selected: root.keyboardSelection && root.selectedIndex === 1

            objectName: "session-reboot-button"
            icon: "󰑐"
            title: "Reboot"
            action: root.requestReboot
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
