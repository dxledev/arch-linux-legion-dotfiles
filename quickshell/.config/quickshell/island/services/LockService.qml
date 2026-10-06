pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../lock"
import "../core"

Singleton {
    id: root

    readonly property bool locked: sessionLock.locked || sessionLock.secure
    readonly property bool secure: sessionLock.secure

    function lock(): void {
        if (locked)
            return;
        console.info("Island lock: lock requested");
        IslandController.reset();
        sessionLock.locked = true;
    }

    LockAuth {
        id: authentication
        locked: sessionLock.secure
        onAuthenticated: {
            console.info("Island lock: releasing session lock");
            sessionLock.locked = false;
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: Quickshell.env("ISLAND_START_LOCKED") === "1"
        onLockedChanged: if (!locked) authentication.reset()
        onSecureChanged: console.info("Island lock: compositor secure=" + secure)

        LockSurface {
            auth: authentication
        }
    }

    Loader {
        active: !root.locked
        asynchronous: true
        onLoaded: active = false
        // Initialize the capture backend before the compositor blocks locked-session capture.
        sourceComponent: ScreencopyView {
            captureSource: Quickshell.screens[0] ?? null
            live: false
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock(); }
        function isLocked(): bool { return root.locked; }
        function state(): string { return root.locked + ":" + root.secure; }
    }
}
