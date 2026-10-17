import QtQuick
import Quickshell
import "../../island"
import "../../services"
import "vendor" as Hyprmoncfg

Item {
    function open(): void {
        if (!editor.opened) {
            const monitorName = IslandState.panelMonitorName || Compositor.focusedMonitorName;
            editor.windowScreen = Quickshell.screens.find(screen => screen.name === monitorName)
                ?? Quickshell.screens[0] ?? null;
        }
        editor.open();
        Qt.callLater(editor.activate);
    }

    function close(): void { editor.close(); }

    Hyprmoncfg.PreviewGuard { id: previewGuard }

    Hyprmoncfg.Panel {
        id: editor
        previewCoordinator: previewGuard
    }
}
