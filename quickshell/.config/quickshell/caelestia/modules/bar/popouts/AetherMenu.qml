pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Column {
    id: root

    required property PopoutState popouts
    readonly property var actions: [
        {
            icon: "open_in_new",
            text: "Open Aether",
            action: "open"
        },
        {
            icon: "close",
            text: "Quit Aether",
            action: "quit"
        }
    ]

    function runAction(action: string): void {
        if (action === "open")
            Aether.launch();
        else if (action === "quit")
            Aether.quit();
        popouts.hasCurrent = false;
    }

    padding: Tokens.padding.small
    spacing: Tokens.spacing.small

    Repeater {
        model: root.actions

        StyledRect {
            id: item

            required property var modelData

            implicitWidth: Tokens.sizes.bar.trayMenuWidth
            implicitHeight: row.implicitHeight
            radius: Tokens.rounding.full
            color: "transparent"

            StateLayer {
                anchors.margins: -Tokens.padding.extraSmall / 2
                anchors.leftMargin: -Tokens.padding.small
                anchors.rightMargin: -Tokens.padding.small
                radius: item.radius
                onClicked: root.runAction(item.modelData.action)
            }

            Row {
                id: row

                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: item.modelData.icon
                    color: Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: item.modelData.text
                    color: Colours.palette.m3onSurface
                }
            }
        }
    }
}
