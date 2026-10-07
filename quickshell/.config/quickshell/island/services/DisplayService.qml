pragma Singleton

import QtQuick
import Quickshell

Singleton {
    function open(): void { host.item?.open(); }
    function close(): void { host.item?.close(); }

    Loader {
        id: host
        source: Qt.resolvedUrl("../modules/display/DisplayHost.qml")
    }
}
