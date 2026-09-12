pragma Singleton

import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.integration

Singleton {
    id: root

    property string style: "active-window"
    readonly property var styles: [
        { id: "active-window", name: "Active Window", icon: "window" },
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
        const perMonitor = GlobalConfig.bar.workspaces.perMonitorWorkspaces;
        const monitor = perMonitor ? Hypr.monitorFor(screen) : Hypr.focusedMonitor;
        const first = perMonitor ? (System.workspaceStarts[screen.name] ?? 1) : 1;
        const ids = Array.from({ length: Math.max(0, Math.min(5, count)) }, (_, index) => first + index);
        for (const workspace of Hypr.workspaces.values) {
            if (workspace.id > 0 && (!perMonitor || workspace.monitor?.name === screen.name)
                && (workspace.lastIpcObject.windows > 0 || workspace.id === monitor?.activeWorkspace?.id)
                && !ids.includes(workspace.id))
                ids.push(workspace.id);
        }
        return ids.sort((a, b) => a - b);
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
