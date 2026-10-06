import QtQuick
import "../components"
import "../services"

Item {
    implicitWidth: Math.max(520, center.implicitWidth + 2 * (leftSection.width + 36))
    implicitHeight: 75
    Row {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        LeftSection { id: leftSection; width: 130; anchors.verticalCenter: parent.verticalCenter }
        Item {
            width: parent.width - leftSection.width - rightSection.width
            height: parent.height
        }
        RightSection {
            id: rightSection
            width: 128
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    CenterSection {
        id: center
        objectName: "expanded-clock-group"
        expanded: true
        anchors.centerIn: parent
    }
}
