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

        StatusChip {
            visible: StatusManager.visible

            icon: StatusManager.icon
            title: StatusManager.title
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