pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "services" as Services

Scope {
    id: root

    property string lastEvent: ""
    property var history: []

    function snapshot(): var {
        return Services.WorkspaceState.snapshot;
    }

    function currentState(): var {
        const current = snapshot();
        return {
            ready: Services.WorkspaceState.ready,
            screen: Services.Fixture.screenName,
            monitor: Services.WorkspaceState.monitorFor(Services.Fixture.targetScreen, true),
            ids: Services.WorkspaceAppearance.visibleIds(Services.Fixture.targetScreen, 5),
            history: root.history,
            raw: current
        };
    }

    FileView {
        id: eventFile

        path: Quickshell.env("TEST_ROOT") + "/event"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const value = text().trim();
            if (value && value !== root.lastEvent) {
                root.lastEvent = value;
                const parts = value.split(":");
                const name = parts[0];
                if (parts.length > 1)
                    Services.Fixture.screenName = parts[1];
                Services.Hyprland.rawEvent({ name });
            }
        }
    }

    FileView {
        id: statusFile

        path: Quickshell.env("TEST_ROOT") + "/status.json"
        blockLoading: true
    }

    Timer {
        interval: 20
        running: true
        repeat: true
        onTriggered: statusFile.setText(JSON.stringify(root.currentState()))
    }

    Connections {
        target: Services.WorkspaceState

        function onSnapshotChanged(): void {
            const current = root.currentState();
            root.history = [...root.history, {
                monitor: current.monitor?.name ?? null,
                ids: current.ids,
                monitors: current.raw?.monitors ?? [],
                workspaces: current.raw?.workspaces ?? [],
                rules: current.raw?.rules ?? []
            }];
        }
    }
}
