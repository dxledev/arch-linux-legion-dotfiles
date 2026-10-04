pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../core"

Singleton {
    id: root
    property var rules: []
    readonly property bool showAllMonitors: ThemeService.settings.workspaceShowAllMonitors ?? false
    readonly property var screen: ThemeService.islandScreens.find(screen => screen.name === Hyprland.focusedMonitor?.name) ?? ThemeService.islandScreens[0]
    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property var visibleWorkspaces: workspacesForMonitor(Hyprland.workspaces.values, monitor?.name, showAllMonitors)
    readonly property int activeWorkspace: (showAllMonitors ? Hyprland.focusedWorkspace : monitor?.activeWorkspace)?.id ?? 1
    readonly property var persistentIds: rules.length === 0 ? null : persistentForMonitor(rules, monitor?.name, showAllMonitors)

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

    function persistentForMonitor(workspaceRules, monitorName, allMonitors) {
        return workspaceRules
            .filter(rule => rule.enabled !== false && rule.persistent && Number(rule.workspaceString) > 0
                && (allMonitors || !rule.monitor || rule.monitor === monitorName))
            .map(rule => Number(rule.workspaceString));
    }

    function showWorkspace() {
        const workspace = Hyprland.focusedWorkspace;
        if (!workspace || (!showAllMonitors && !ThemeService.islandScreens.some(screen => screen.name === workspace.monitor?.name))) return;
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
