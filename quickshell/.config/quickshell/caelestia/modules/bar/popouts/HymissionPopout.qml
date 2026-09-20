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
            icon: "view_quilt",
            text: "Show Overview",
            action: "overview"
        },
        {
            icon: "dashboard",
            text: "Show Mission Control",
            action: "missionControl"
        }
    ]

    function runAction(action: string): void {
        if (action === "overview")
            HymissionActions.showOverview();
        else if (action === "missionControl")
            HymissionActions.showMissionControl();

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
