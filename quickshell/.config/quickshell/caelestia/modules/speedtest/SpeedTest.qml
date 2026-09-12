pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    function open(kind: string, screen: ShellScreen): void {
        if (kind !== "network" && kind !== "disk")
            return;
        const panel = kind === "network" ? network : disk;
        const other = kind === "network" ? disk : network;
        other.close();
        panel.screen = screen;
        panel.open("{}");
    }

    NetworkPanel { id: network }
    DiskPanel { id: disk }
}
