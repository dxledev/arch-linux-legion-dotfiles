pragma Singleton

import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.integration
import "WorkspaceModel.js" as Model

Singleton {
    id: root

    property string style: "active-window"
    readonly property var styles: [
        { id: "active-window", name: "Default", icon: "window" },
        { id: "simple", name: "Simple", icon: "horizontal_rule" },
        { id: "numbered", name: "Numbered", icon: "format_list_numbered" }
    ]

    function selectStyle(value: string): void {
        if (!styles.some(item => item.id === value))
            return;
        style = value;
        settings.setText(JSON.stringify({ style: value }) + "\n");
    }

    function visibleIds(screen: ShellScreen, count: int): var {
        const snapshot = WorkspaceState.snapshot;
        if (!snapshot)
            return [];

        const perMonitor = GlobalConfig.bar.workspaces.perMonitorWorkspaces;
        const monitor = WorkspaceState.monitorFor(screen, perMonitor);
        const first = perMonitor ? (System.workspaceStarts[screen.name] ?? 1) : 1;
        return Model.visibleIds(monitor, snapshot.workspaces, snapshot.rules, count, first, perMonitor);
    }

    FileView {
        id: settings
        path: Quickshell.shellPath("active/config/workspace-icons.json")
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const value = JSON.parse(text()).style;
                if (root.styles.some(item => item.id === value))
                    root.style = value;
            } catch (error) {
                console.warn("Could not load workspace icon style:", error);
            }
        }
    }
}
