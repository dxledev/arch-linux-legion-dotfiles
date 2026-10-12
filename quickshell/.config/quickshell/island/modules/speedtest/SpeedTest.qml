import QtQuick
import Quickshell

import "../../core"

// Opens Caelestia's network or disk speed test overlay on the requested monitor.
Scope {
    id: root

    function open(kind, monitorName) {
        if (kind !== "network" && kind !== "disk")
            return;
        const panel = kind === "network" ? network : disk;
        const other = kind === "network" ? disk : network;
        other.close();
        panel.screen = Quickshell.screens.find(screen => screen.name === monitorName) ?? Quickshell.screens[0] ?? null;
        panel.open("{}");
    }

    Connections {
        target: IslandController

        function onSpeedTestRequested(kind, monitorName) {
            root.open(kind, monitorName)
        }
    }

    NetworkPanel { id: network }
    DiskPanel { id: disk }
}
