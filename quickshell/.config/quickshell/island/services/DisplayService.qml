pragma Singleton

import QtQuick
import Quickshell

Singleton {
    function open(): void { host.item?.open(); }
    function close(): void { host.item?.close(); }

    Loader {
        id: host
        // The editor drives the shared hyprmoncfg backend, which only speaks to Hyprland.
        active: Compositor.hasDisplayEditor
        source: Qt.resolvedUrl("../modules/display/DisplayHost.qml")
    }
}
