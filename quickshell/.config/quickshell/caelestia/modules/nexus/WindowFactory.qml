pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus

Singleton {
    id: root

    property var nexusWindow

    function findNexusClient(): var {
        return Hypr.toplevels.values.find(t =>
            t.title?.startsWith("Nexus — ")
        ) ?? null;
    }

    function focusNexusClient(client: var): void {
        if (!client?.address)
            return;

        Hypr.dispatch(Hypr.usingLua
            ? `hl.dsp.focus({ window = "address:0x${client.address}" })`
            : `focuswindow address:0x${client.address}`);
    }

    function revealNexus(): void {
        Hypr.dispatch(Hypr.usingLua
            ? 'hl.dsp.focus({ monitor = "HDMI-A-1" })'
            : 'focusmonitor HDMI-A-1');

        Hypr.dispatch(Hypr.usingLua
            ? 'hl.dsp.focus({ workspace = "special:nexus" })'
            : 'workspace special:nexus');
    }

    function revealAndActivate(client: var): void {
        revealNexus();

        const backingWindow = nexusWindow?.contentItem?.window;
        if (backingWindow)
            backingWindow.requestActivate();
        else
            focusNexusClient(client);
    }

    function create(parent: Item, props: var): void {
        const existingClient = findNexusClient();
        if (nexusWindow || existingClient) {
            revealAndActivate(existingClient);
            return;
        }

        revealNexus();
        nexusWindow = nexusComp.createObject(parent ?? dummy, props ?? {});
    }

    QtObject {
        id: dummy
    }

    Component {
        id: nexusComp

        FloatingWindow {
            id: win

            color: Colours.tPalette.m3surface
            surfaceFormat.opaque: false

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            onClosed: destroy()

            Component.onDestruction: {
                if (root.nexusWindow === win)
                    root.nexusWindow = null;
            }

            implicitWidth: nexus.implicitWidth
            implicitHeight: nexus.implicitHeight

            minimumSize.width: contentItem.Tokens.sizes.nexus.minWidth
            minimumSize.height: contentItem.Tokens.sizes.nexus.minHeight

            contentItem.Config.screen: screen.name
            contentItem.Tokens.screen: screen.name

            title: Tr.tr("Nexus — %1").arg(PageRegistry.pages[nexus.nState.currentPageIdx].label)

            Nexus {
                id: nexus

                anchors.fill: parent
                nState.screen: win.screen
                nState.isWindow: true
                onClose: win.destroy()
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
