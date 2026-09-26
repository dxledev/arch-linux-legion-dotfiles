pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

Column {
    id: root

    required property PopoutState popouts

    padding: Tokens.padding.small
    spacing: Tokens.spacing.small

    StyledRect {
        id: statusItem

        implicitWidth: Tokens.sizes.bar.trayMenuWidth
        implicitHeight: statusRow.implicitHeight
        radius: Tokens.rounding.full
        color: "transparent"

        StateLayer {
            anchors.margins: -Tokens.padding.extraSmall / 2
            anchors.leftMargin: -Tokens.padding.small
            anchors.rightMargin: -Tokens.padding.small
            radius: statusItem.radius
            onClicked: Sunshine.toggle()
        }

        Row {
            id: statusRow

            spacing: Tokens.spacing.medium

            MaterialIcon {
                animate: true
                text: Sunshine.state === "running" ? "cast_connected" : "cast"
                color: Colours.palette.m3onSurface
                fontStyle: Tokens.font.icon.small
                fill: 1
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Sunshine.state === "running" ? Tr.tr("Sunshine: ON") : Tr.tr("Sunshine: OFF")
                color: Colours.palette.m3onSurface
            }
        }
    }

    StyledRect {
        id: openItem

        implicitWidth: Tokens.sizes.bar.trayMenuWidth
        implicitHeight: row.implicitHeight
        radius: Tokens.rounding.full
        color: "transparent"

        StateLayer {
            anchors.margins: -Tokens.padding.extraSmall / 2
            anchors.leftMargin: -Tokens.padding.small
            anchors.rightMargin: -Tokens.padding.small
            radius: openItem.radius
            onClicked: {
                Sunshine.openWebUi();
                root.popouts.hasCurrent = false;
            }
        }

        Row {
            id: row

            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: "open_in_browser"
                color: Colours.palette.m3onSurface
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Tr.tr("Open Sunshine")
                color: Colours.palette.m3onSurface
            }
        }
    }
}
