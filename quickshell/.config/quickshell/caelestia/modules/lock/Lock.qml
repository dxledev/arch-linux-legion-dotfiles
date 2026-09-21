pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components.misc

Scope {
    id: root

    property bool startLocked
    property bool nativeLockProvider
    property alias lock: lock
    readonly property bool secure: lock.secure

    WlSessionLock {
        id: lock

        locked: root.startLocked && !root.nativeLockProvider

        signal unlock

        onLockedChanged: {
            if (!locked)
                root.startLocked = false;
        }

        LockSurface {
            lock: lock
            pam: pam
            startup: root.startLocked
        }
    }

    Pam {
        id: pam

        lock: lock
    }

    Loader {
        asynchronous: true
        active: true
        onLoaded: active = false

        // Force a load of a screencopy so the one in the lock works
        // My guess is the ICC backend loads async on first request, which if the lock is
        // the first request it fails to capture (because it's async and the compositor
        // refuses capture when locked)
        sourceComponent: ScreencopyView {
            captureSource: Quickshell.screens[0]
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "lock"
        description: "Lock the current session"
        onPressed: {
            if (!root.nativeLockProvider)
                lock.locked = true;
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "unlock"
        description: "Unlock the current session"
        onPressed: lock.unlock()
    }

    IpcHandler {
        function lock(): void {
            if (!root.nativeLockProvider)
                lock.locked = true;
        }

        function unlock(): void {
            lock.unlock();
        }

        function isLocked(): bool {
            return !root.nativeLockProvider && lock.locked;
        }

        function state(): string {
            return `${!root.nativeLockProvider && lock.locked}:${!root.nativeLockProvider && lock.secure}`;
        }

        target: "lock"
    }
}
