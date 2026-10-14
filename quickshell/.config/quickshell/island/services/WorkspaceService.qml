pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../core"
import "../island"
import "MonitorSelection.js" as MonitorSelection

Singleton {
    id: root
    property var rules: []
    readonly property bool showAllMonitors: ThemeService.settings.workspaceShowAllMonitors ?? false
    readonly property var screen: ThemeService.islandScreens.find(screen => screen.name === Hyprland.focusedMonitor?.name) ?? ThemeService.islandScreens[0]
    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property var visibleWorkspaces: workspacesForMonitor(Hyprland.workspaces.values, monitor?.name, showAllMonitors)
    readonly property int activeWorkspace: (showAllMonitors ? Hyprland.focusedWorkspace : monitor?.activeWorkspace)?.id ?? 1
    readonly property var persistentIds: rules.length === 0 ? null : persistentForMonitor(rules, monitor, showAllMonitors)

    function hasFullscreen(screenMonitor) {
        const specialName = screenMonitor?.lastIpcObject.specialWorkspace?.name;
        const workspace = specialName
            ? Hyprland.workspaces.values.find(workspace => workspace.name === specialName)
            : screenMonitor?.activeWorkspace;
        return workspace?.toplevels.values.some(window => window.lastIpcObject.fullscreen > 1) ?? false;
    }

    function workspacesForMonitor(workspaces, monitorName, allMonitors) {
        return workspaces.filter(workspace => allMonitors || workspace.monitor?.name === monitorName);
    }

    function ruleMatchesMonitor(selector, screenMonitor) {
        if (!selector) return true;
        if (!screenMonitor) return false;
        if (selector === screenMonitor.name) return true;
        const description = screenMonitor.description || screenMonitor.lastIpcObject?.description || "";
        return !!description && selector === "desc:" + description;
    }

    function persistentForMonitor(workspaceRules, screenMonitor, allMonitors) {
        return workspaceRules
            .filter(rule => rule.enabled !== false && rule.persistent && Number(rule.workspaceString) > 0
                && (allMonitors || ruleMatchesMonitor(rule.monitor, screenMonitor)))
            .map(rule => Number(rule.workspaceString));
    }

    // The expanded island's workspace section already shows the active workspace, so its monitor
    // skips the workspace OSD (other OSDs keep using the attached drawer below the section).
    function workspacePanelCovers(monitorName) {
        return IslandState.workspacePanelOpen && IslandState.mode === IslandState.expandedMode
            && MonitorSelection.osdMonitorName(monitorName, ThemeService.islandScreens) === IslandState.panelMonitorName;
    }

    // Numbered workspaces to list: the persistent set plus anything occupied or active.
    function workspaceEntries(workspaces, persistentIds, persistent, persistentCount, activeWorkspace) {
        const states = new Map();
        if (persistent) {
            const ids = persistentIds == null
                ? Array.from({length: persistentCount}, (_, index) => index + 1)
                : [...new Set(persistentIds)].sort((a, b) => a - b).slice(0, persistentCount);
            for (const id of ids) states.set(id, false);
        }
        for (const workspace of workspaces ?? []) {
            if (workspace.id <= 0) continue;
            const occupied = (workspace.toplevels?.values.length ?? workspace.lastIpcObject?.windows ?? 0) > 0;
            if (states.has(workspace.id) || occupied || workspace.id === activeWorkspace)
                states.set(workspace.id, occupied);
        }
        if (activeWorkspace > 0 && !states.has(activeWorkspace))
            states.set(activeWorkspace, false);
        return [...states].sort((a, b) => a[0] - b[0]).map(([id, occupied]) => ({id, occupied}));
    }

    readonly property var specialPrimary: ["discordspace", "mediaspace", "scratchpad", "socialspace"]
    // Caelestia's own special workspaces; Island never lists them.
    readonly property var specialExcluded: ["aether", "nexus"]

    // Special workspaces to list: the four named ones always, then every other special
    // workspace that exists or is named by a rule. `occupied` is false when no window is in it.
    function specialEntries(workspaces, toplevels, workspaceRules, activeSpecialName) {
        const extra = new Set();
        const bare = name => String(name ?? "").replace(/^special:/, "");
        for (const workspace of workspaces ?? [])
            if (workspace.id < 0 || String(workspace.name).startsWith("special:")) extra.add(bare(workspace.name));
        for (const rule of workspaceRules ?? [])
            if (rule.enabled !== false && String(rule.workspaceString ?? "").startsWith("special:")) extra.add(bare(rule.workspaceString));
        for (const name of specialPrimary) extra.delete(name);
        extra.delete("");
        for (const name of specialExcluded) extra.delete(name);
        const names = [...specialPrimary, ...[...extra].sort()];
        return names.map(name => ({
            name,
            occupied: (toplevels ?? []).some(window => bare(window.workspace?.name ?? window.lastIpcObject?.workspace?.name) === name),
            active: bare(activeSpecialName) === name
        }));
    }

    function showWorkspace() {
        const workspace = Hyprland.focusedWorkspace;
        if (!workspace || (!showAllMonitors && !ThemeService.islandScreens.some(screen => screen.name === workspace.monitor?.name))) return;
        if (workspacePanelCovers(workspace.monitor?.name ?? Hyprland.focusedMonitor?.name ?? "")) return;
        StatusManager.show({
            mode: "workspace", icon: "", title: workspace.name, value: workspace.id,
            monitorName: workspace.monitor?.name ?? Hyprland.focusedMonitor?.name ?? "",
            statusWidth: 200, statusHeight: 33
        });
    }

    Process {
        id: ruleReader
        command: ["/usr/bin/hyprctl", "-j", "workspacerules"]
        running: !!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
        stdout: StdioCollector {}
        onExited: function(code) {
            if (code !== 0) return;
            try { root.rules = JSON.parse(stdout.text); }
            catch (error) { console.warn("Could not read workspace rules: " + error); }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {

            if (event.name === "workspace") Qt.callLater(root.showWorkspace);
            if (event.name === "configreloaded") ruleReader.running = true;
            if (event.name === "fullscreen") Hyprland.refreshToplevels();
            if (event.name === "activespecial") Hyprland.refreshMonitors();
        }
    }
}
