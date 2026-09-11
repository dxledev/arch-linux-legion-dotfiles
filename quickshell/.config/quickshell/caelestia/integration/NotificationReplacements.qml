import QtQuick
import Quickshell.Io

Process {
    id: root

    signal replaced(string notificationId)
    property bool awaitingId: false

    // Quickshell has no replacement signal when all notification properties stay unchanged.
    running: true
    command: ["/usr/bin/dbus-monitor", "--session", "type='method_call',interface='org.freedesktop.Notifications',member='Notify',path='/org/freedesktop/Notifications'"]

    stdout: SplitParser {
        onRead: line => {
            if (line.startsWith("method call")) {
                root.awaitingId = true;
                return;
            }
            if (!root.awaitingId)
                return;
            const match = line.match(/^\s+uint32 (\d+)\s*$/);
            if (match) {
                root.awaitingId = false;
                if (match[1] !== "0")
                    root.replaced(match[1]);
            }
        }
    }

    onExited: retry.restart()

    property Timer retryTimer: Timer {
        id: retry
        interval: 2000
        onTriggered: root.running = true
    }
}
