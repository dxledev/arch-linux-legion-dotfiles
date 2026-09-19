import QtQuick
import Caelestia.Config
import qs.components
import qs.modules.nexus

Item {
    id: root

    required property NexusState nState

    property int lastPageIdx
    property int animOff
    property var currentItem
    property list<int> pendingSubPagePath: []
    property int pendingPageIdx: -1
    property int loadGeneration

    function applyPendingSubPagePath(pageIdx: int): void {
        if (root.pendingPageIdx !== pageIdx || !root.currentItem)
            return;

        const path = root.pendingSubPagePath;
        root.pendingPageIdx = -1;
        root.nState.subPageIdxStack = path;
        if (typeof root.currentItem.navigateTo === "function")
            root.currentItem.navigateTo(path);
    }

    function loadPage(idx: int): void {
        const generation = ++root.loadGeneration;
        if (root.currentItem) {
            root.currentItem.destroy();
            root.currentItem = null;
        }

        const comp = PageCompRegistry.pageComps[idx] ?? PageCompRegistry.placeholderComp;
        const incubator = comp.incubateObject(container, {
            nState: root.nState
        });

        const attach = () => {
            if (!root || generation !== root.loadGeneration || !incubator.object) {
                incubator.object?.destroy();
                return;
            }

            incubator.object.anchors.fill = container;
            root.currentItem = incubator.object;
            root.applyPendingSubPagePath(idx);
        };

        if (incubator.status === Component.Ready)
            attach();
        else
            incubator.onStatusChanged = status => {
                if (status === Component.Ready)
                    attach();
            };
    }

    Item {
        id: container

        objectName: "PageContainer"
        anchors.fill: parent
        layer.enabled: opacity < 1
        Component.onCompleted: root.loadPage(root.nState.currentPageIdx)
    }

    Connections {
        function onNavigationRequested(pageIdx: int, path: var): void {
            root.pendingPageIdx = pageIdx;
            root.pendingSubPagePath = Array.from(path ?? []).map(index => Number(index));
            if (pageIdx === root.nState.currentPageIdx)
                root.applyPendingSubPagePath(pageIdx);
        }

        function onCurrentPageIdxChanged(): void {
            root.pendingPageIdx = -1;
            switchAnim.complete();
            root.animOff = root.Tokens.padding.extraLarge * (root.nState.currentPageIdx > root.lastPageIdx ? 1 : -1);
            switchAnim.start();
            root.lastPageIdx = root.nState.currentPageIdx;
        }

        target: root.nState
    }

    SequentialAnimation {
        id: switchAnim

        Anim {
            target: container
            property: "opacity"
            to: 0
            type: Anim.DefaultEffects
        }
        ScriptAction {
            script: root.loadPage(root.nState.currentPageIdx)
        }
        PropertyAction {
            target: container.anchors
            property: "topMargin"
            value: root.animOff
        }
        PropertyAction {
            target: container.anchors
            property: "bottomMargin"
            value: -root.animOff
        }
        ParallelAnimation {
            Anim {
                target: container
                property: "opacity"
                from: 0
                to: 1
                type: Anim.SlowEffects
            }
            Anim {
                target: container.anchors
                properties: "topMargin,bottomMargin"
                to: 0
                type: Anim.SlowEffects
            }
        }
    }
}
