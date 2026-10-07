pragma Singleton

import QtQuick
import Quickshell
import qs.services
import qs.modules.display.vendor as Hyprmoncfg

Singleton {
    id: root

    function open(): void {
        if (!editor.opened)
            editor.windowScreen = ShellState.forActive()?.modelData ?? Quickshell.screens[0] ?? null;
        editor.open();
        Qt.callLater(editor.activate);
    }

    function close(): void {
        editor.close();
    }

    Hyprmoncfg.PreviewGuard {
        id: previewGuard
    }

    Hyprmoncfg.Panel {
        id: editor

        previewCoordinator: previewGuard
    }
}
