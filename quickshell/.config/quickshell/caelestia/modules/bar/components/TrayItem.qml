pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components.effects
import qs.services
import qs.utils

MouseArea {
    id: root

    required property SystemTrayItem modelData

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    implicitWidth: Tokens.font.body.small.pointSize * 2
    implicitHeight: Tokens.font.body.small.pointSize * 2

    function activate(): void {
        if (modelData.id === "spotify-client") {
            Quickshell.execDetached(["/home/dxle/bin/hypr-focus-special-workspace", "mediaspace"]);
            return;
        }

        modelData.activate();
    }

    onClicked: event => {
        if (event.button === Qt.LeftButton)
            activate();
        else
            modelData.secondaryActivate();
    }

    ColouredIcon {
        id: icon

        anchors.fill: parent
        source: Icons.getTrayIcon(root.modelData.id, root.modelData.icon)
        colour: Colours.palette.m3secondary
        layer.enabled: Config.bar.tray.recolour

        transform: Translate {
            x: root.modelData.id === "vesktop_status_icon_1" ? 1 : 0
        }
    }
}
