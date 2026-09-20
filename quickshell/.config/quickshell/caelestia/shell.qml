pragma ComponentBehavior: Bound

//@ pragma Env QS_CRASHREPORT_URL=https://github.com/caelestia-dots/shell/issues/new?template=crash.yml
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma DefaultEnv QML_IMPORT_PATH=/home/dxle/.config/quickshell/.runtime/qml
//@ pragma DefaultEnv CAELESTIA_LIB_DIR=/home/dxle/.config/quickshell/.runtime/lib/caelestia

import "modules/lock"
import QtQuick
import Quickshell

ShellRoot {
    id: root

    readonly property bool startupLocked: Quickshell.env("CAELESTIA_START_LOCKED") === "1"
    property bool shellContentRequested

    function loadShellContent(): void {
        if (shellContentRequested)
            return;

        shellContentRequested = true;
        shellLoader.setSource(Quickshell.shellPath("active/deferred/Shell.qml"), {
            lock: lockController,
            shellRoot: root
        });
    }

    settings.watchFiles: false

    Lock {
        id: lockController

        startLocked: root.startupLocked
        onSecureChanged: {
            if (secure)
                root.loadShellContent();
        }
    }

    Loader {
        id: shellLoader

        asynchronous: root.startupLocked
    }

    Component.onCompleted: {
        if (!root.startupLocked || lockController.secure)
            root.loadShellContent();
    }
}
