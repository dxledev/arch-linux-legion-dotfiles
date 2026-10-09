pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    property var snapshot: null
    property int pendingQueries: 0
    property bool refreshPending: false

    readonly property bool ready: snapshot !== null
    readonly property var monitors: snapshot?.monitors ?? []
    readonly property var workspaces: snapshot?.workspaces ?? []
    readonly property var rules: snapshot?.rules ?? []

    function monitorFor(screen: ShellScreen, perMonitor: bool): var {
        return snapshot?.monitors.find(monitor => perMonitor ? monitor.name === screen.name : monitor.focused) ?? null;
    }

    function refresh(): void {
        if (pendingQueries > 0)
            refreshPending = true;
        else
            refreshTimer.restart();
    }

    function startRefresh(): void {
        pendingQueries = 3;
        monitorsQuery.refresh();
        workspacesQuery.refresh();
        rulesQuery.refresh();
    }

    function finishRefresh(): void {
        pendingQueries--;
        if (pendingQueries > 0)
            return;

        if (refreshPending) {
            refreshPending = false;
            refresh();
            return;
        }

        if (monitorsQuery.valid && workspacesQuery.valid && rulesQuery.valid) {
            retryTimer.stop();
            snapshot = {
                monitors: monitorsQuery.data,
                workspaces: workspacesQuery.data,
                rules: rulesQuery.data
            };
        } else {
            retryTimer.restart();
        }
    }

    Component.onCompleted: refresh()

    Timer {
        id: refreshTimer

        interval: 50
        onTriggered: root.startRefresh()
    }

    Timer {
        id: retryTimer

        interval: 500
        onTriggered: root.refresh()
    }

    Connections {
        target: Quickshell

        function onScreensChanged(): void {
            root.refresh();
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            const name = event.name.replace(/v2$/, "");
            if (name === "configreloaded" || name === "focusedmon" || name.includes("monitor")
                || name.includes("workspace") || ["openwindow", "closewindow", "movewindow", "activespecial"].includes(name))
                root.refresh();
        }
    }

    Query {
        id: monitorsQuery
        request: "monitors"
        onCollected: root.finishRefresh()
    }

    Query {
        id: workspacesQuery
        request: "workspaces"
        onCollected: root.finishRefresh()
    }

    Query {
        id: rulesQuery
        request: "workspacerules"
        onCollected: root.finishRefresh()
    }

    component Query: Process {
        id: query

        required property string request
        property var data: []
        property bool valid: false

        signal collected()

        function refresh(): void {
            valid = false;
            running = true;
        }

        command: ["/usr/bin/hyprctl", "-j", request]

        stdout: StdioCollector {
            id: output
        }

        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    const snapshot = JSON.parse(output.text);
                    if (Array.isArray(snapshot)) {
                        data = snapshot;
                        valid = true;
                    }
                } catch (error) {
                    console.warn("Could not read Hyprland", request, "state:", error);
                }
            }
            collected();
        }
    }
}
