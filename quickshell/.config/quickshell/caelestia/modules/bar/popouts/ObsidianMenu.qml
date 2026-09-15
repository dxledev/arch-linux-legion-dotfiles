pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Column {
    id: root

    required property PopoutState popouts

    readonly property var obsidianClient:
        Hypr.toplevels.values.find(t =>
            t.lastIpcObject.class === "md.obsidian.Obsidian"
            && t.lastIpcObject.mapped
        ) ?? null

    readonly property var actions: [
        {
            icon: "open_in_new",
            text: "Open Obsidian",
            action: "open"
        },
        {
            icon: "close",
            text: "Quit Obsidian",
            action: "quit"
        }
    ]

    function runAction(action: string): void {
        if (action === "open") {
            Quickshell.execDetached([
                "/home/dxle/bin/hypr-focus-special-workspace",
                "scratchpad"
            ]);
        } else if (action === "quit" && obsidianClient) {
            Hypr.dispatch(
                Hypr.usingLua
                    ? `hl.dsp.window.kill({ window = "address:0x${obsidianClient.address}" })`
                    : `killwindow address:0x${obsidianClient.address}`
            );
        }

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
