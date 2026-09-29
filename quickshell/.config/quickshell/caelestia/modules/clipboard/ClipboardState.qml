pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.integration
import qs.services
import qs.modules.chromack as Chromack
import Shell.Clipboard

Singleton {
    id: root

    property ShellScreen screen: null
    property bool isOpen: false
    property int openingId: 0
    readonly property var options: System.clipboard
    readonly property alias controller: controller
    signal focusRequested

    function open(): void {
        const activeState = ShellState.forActive();
        const target = activeState?.modelData ?? Quickshell.screens[0] ?? null;
        if (!target)
            return;

        for (const monitor of Quickshell.screens) {
            const state = ShellState.forScreen(monitor);
            if (state)
                state.launcher = false;
        }
        if (Chromack.ChromackState.isOpen)
            Chromack.ChromackState.close(false);

        screen = target;
        openingId++;
        isOpen = true;
        controller.refresh();
        Qt.callLater(() => focusRequested());
    }

    function close(): void {
        isOpen = false;
    }

    function toggle(): void {
        if (isOpen)
            close();
        else
            open();
    }

    ClipboardController {
        id: controller
        cliphistPath: root.options.cliphistPath
        wlCopyPath: root.options.wlCopyPath
        historyDatabasePath: root.options.historyDatabasePath
        Component.onCompleted: initialize()
    }

    Timer {
        interval: Math.max(200, root.options.historyRefreshMs ?? 2000)
        repeat: true
        running: root.isOpen
        onTriggered: controller.refresh()
    }

    Connections {
        target: Chromack.ChromackState
        function onIsOpenChanged(): void {
            if (Chromack.ChromackState.isOpen)
                root.close();
        }
    }

    Connections {
        target: controller
        function onCopyCompleted(key: string, success: bool, message: string): void {
            if (success)
                root.close();
        }
    }

    Instantiator {
        model: Quickshell.screens
        delegate: Connections {
            required property ShellScreen modelData
            property var screenState: ShellState.forScreen(modelData)
            target: screenState
            function onLauncherChanged(): void {
                if (screenState?.launcher)
                    root.close();
            }
        }
    }

    Connections {
        target: Quickshell
        function onScreensChanged(): void {
            if (!root.isOpen || Quickshell.screens.includes(root.screen))
                return;
            const active = ShellState.forActive()?.modelData ?? Quickshell.screens[0] ?? null;
            if (active) {
                root.screen = active;
            } else {
                root.close();
            }
        }
    }
}
