pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property Repeater workspaces
    required property var occupied
    required property var workspaceIds

    property list<var> pills: []

    function updatePills(): void {
        let count = 0;
        for (let index = 0; index < workspaceIds.length; index++) {
            const ws = workspaceIds[index];
            if (!occupied[ws])
                continue;
            if (index === 0 || !occupied[workspaceIds[index - 1]]) {
                if (pills[count])
                    pills[count].start = ws;
                else
                    pills.push(pillComp.createObject(root, { start: ws }));
                count++;
            }
            pills[count - 1].end = ws;
        }
        if (pills.length > count)
            pills.splice(count).forEach(pill => pill.destroy());
    }

    onOccupiedChanged: updatePills()
    onWorkspaceIdsChanged: updatePills()
    Component.onCompleted: updatePills()

    Repeater {
        model: ScriptModel {
            values: root.pills.filter(p => p)
        }

        StyledRect {
            id: rect

            required property var modelData

            readonly property Workspace start: root.workspaces.count > 0 ? root.workspaces.itemAt(getWsIdx(modelData.start)) ?? null : null // qmllint disable incompatible-type
            readonly property Workspace end: root.workspaces.count > 0 ? root.workspaces.itemAt(getWsIdx(modelData.end)) ?? null : null // qmllint disable incompatible-type

            function getWsIdx(ws: int): int {
                return root.workspaceIds.indexOf(ws);
            }

            anchors.horizontalCenter: root.horizontalCenter

            y: (start?.y ?? 0) - 1
            implicitWidth: Tokens.sizes.bar.innerWidth - Tokens.padding.small + 2
            implicitHeight: start && end ? end.y + end.size - start.y + 2 : 0

            color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
            radius: Tokens.rounding.full

            scale: 0
            Component.onCompleted: scale = 1

            Behavior on scale {
                Anim {
                    easing: Tokens.anim.standardDecel
                }
            }

            Behavior on y {
                Anim {}
            }

            Behavior on implicitHeight {
                Anim {}
            }
        }
    }

    Component {
        id: pillComp

        Pill {}
    }

    component Pill: QtObject {
        property int start
        property int end
    }
}
