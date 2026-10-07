import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../island"
import "vendor" as Hyprmoncfg

Item {
    function open(): void {
        if (!editor.opened) {
            const monitorName = IslandState.panelMonitorName || Hyprland.focusedMonitor?.name;
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
