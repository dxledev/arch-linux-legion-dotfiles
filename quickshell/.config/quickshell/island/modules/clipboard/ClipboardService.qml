pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Shell.Clipboard

// Clipboard history backed by cliphist through the Shell.Clipboard plugin that
// Caelestia also uses, so pinned entries and thumbnails are shared between shells.
Singleton {
    id: root

    readonly property alias controller: controller
    readonly property bool loading: controller.loading
    readonly property bool clearingHistory: controller.clearingHistory
    readonly property bool deleting: controller.deleting
    readonly property string errorMessage: controller.errorMessage
    property bool historyRefreshCompleted: false
    property int listUsers: 0
    property string pendingCopyKey: ""
    property bool dismissAfterCopy: true

    signal copyFinished(string key, bool success, bool dismissed)

    function acquireList() {
        listUsers++;
        controller.refresh();
    }

    function releaseList() {
        listUsers = Math.max(0, listUsers - 1);
        pendingCopyKey = "";
    }

    function copyEntry(key, closeAfterCopy) {
        if (!key)
            return;
        pendingCopyKey = key;
        dismissAfterCopy = closeAfterCopy;
        controller.copyEntry(key);
    }

    ClipboardController {
        id: controller
        cliphistPath: Quickshell.env("ISLAND_CLIPHIST_BIN") || "/usr/bin/cliphist"
        wlCopyPath: Quickshell.env("ISLAND_WL_COPY_BIN") || "/usr/bin/wl-copy"
        Component.onCompleted: initialize()
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.listUsers > 0
        onTriggered: controller.refresh()
    }

    Connections {
        target: controller
        function onLoadingChanged() {
            if (!controller.loading)
                root.historyRefreshCompleted = true;
        }
        function onCopyCompleted(key, success, message) {
            if (key !== root.pendingCopyKey)
                return;
            root.pendingCopyKey = "";
            const dismissed = success && root.dismissAfterCopy;
            if (dismissed)
                Quickshell.execDetached(["notify-send", "-a", "Island Clipboard", "-i", "edit-copy", "-t", "2000", "Clipboard", "Copied to clipboard"]);
            root.copyFinished(key, success, dismissed);
        }
    }
}
