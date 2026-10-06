import QtQuick

import "../styles"
import "../core"

Item {

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row

        anchors.right: parent.right
        anchors.rightMargin: Theme.sectionGap
        anchors.verticalCenter: parent.verticalCenter

        spacing: 10

        IconButton {
            objectName: "session-menu-button"
            anchors.verticalCenter: parent.verticalCenter
            iconSource: "../assets/icons/power.svg"
            description: "Session menu"
            onClicked: {
                IslandController.ignoreNextIslandTap();
                IslandController.openPowerMenuFromRightSection();
            }
        }
        IconButton {
            objectName: "control-center-button"
            anchors.verticalCenter: parent.verticalCenter
            iconSource: "../assets/icons/control-center.svg"
            description: "Control Center"
            onClicked: {
                IslandController.ignoreNextIslandTap();
                IslandController.openControlCenterFromRightSection();
            }
        }
        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            iconSource: "../assets/icons/more-vertical.svg"
            description: "Island menu"
            onClicked: IslandController.openNavigation()
        }
    }
}
