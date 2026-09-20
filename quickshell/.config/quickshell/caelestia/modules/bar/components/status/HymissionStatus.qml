pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

MouseArea {
    id: root

    required property color colour

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    implicitWidth: Tokens.font.body.small.pointSize * 2
    implicitHeight: Tokens.font.body.small.pointSize * 2

    onClicked: event => {
        if (event.button === Qt.LeftButton)
            HymissionActions.showOverview();
        else if (event.button === Qt.RightButton)
            HymissionActions.showMissionControl();
    }

    MaterialIcon {
        anchors.fill: parent

        animate: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "view_quilt"
        color: root.colour
        fontStyle: Tokens.font.icon.medium
        fill: 1
    }
}
