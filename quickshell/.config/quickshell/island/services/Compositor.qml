pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "NiriModel.js" as NiriModel

// Which compositor Island is running under, and the few operations that differ between them. Under
// Hyprland every property here simply forwards to Quickshell.Hyprland, so nothing changes there; under niri
// the same questions are answered from NiriService. ISLAND_COMPOSITOR=niri|hyprland forces a choice.
Singleton {
    id: root

    readonly property string name: NiriModel.detectWith(variable => Quickshell.env(variable))
    readonly property bool niri: name === "niri"

    // Name of the monitor holding the focus; undefined until the compositor reports one.
    readonly property var focusedMonitorName: niri ? NiriService.focusedOutput : Hyprland.focusedMonitor?.name
    readonly property var workspaces: niri ? NiriService.workspaces : Hyprland.workspaces.values
    readonly property var focusedWorkspace: niri ? NiriService.focusedWorkspace : Hyprland.focusedWorkspace
    // Windows as the workspace lists see them; niri has no Hyprland toplevel objects, only counts.
    readonly property var toplevels: niri ? [] : Hyprland.toplevels.values

    // Special (scratchpad-like) workspaces, per-spawn window rules and the layout/axis switches are
    // Hyprland features; the menus hide what depends on them under niri.
    readonly property bool hasSpecialWorkspaces: !niri
    readonly property bool hasLayoutControls: !niri
    readonly property bool hasDisplayEditor: !niri
    readonly property bool hasKeybindList: !niri
    readonly property bool hasNightLight: !niri
    // toggle-shell-mode edits Hyprland's config and reloads it; there is no niri counterpart.
    readonly property bool hasShellModes: !niri
    readonly property bool hasWindowRounding: !niri

    function monitorFor(screen) {
        return niri ? NiriService.monitorFor(screen) : Hyprland.monitorFor(screen);
    }

    // True when a fullscreen window covers the monitor, so the island and the screen corners step aside.
    // `monitor` is what monitorFor returned. niri's IPC does not say which windows are fullscreen, but its
    // foreign-toplevel protocol does.
    function hasFullscreen(monitor) {
        if (!niri) {
            const specialName = monitor?.lastIpcObject.specialWorkspace?.name;
            const workspace = specialName
                ? Hyprland.workspaces.values.find(workspace => workspace.name === specialName)
                : monitor?.activeWorkspace;
            return workspace?.toplevels.values.some(window => window.lastIpcObject.fullscreen > 1) ?? false;
        }
        const screenName = monitor?.name;
        if (!screenName) return false;
        return ToplevelManager.toplevels.values.some(toplevel => toplevel.fullscreen
            && toplevel.screens.some(screen => screen.name === screenName));
    }

    // Focuses workspace `id` (the number the workspace lists show). On niri that is the index on the
    // monitor the panel belongs to, so the focus moves to that monitor first.
    function focusWorkspace(id, monitorName) {
        if (niri) NiriService.focusWorkspace(id, monitorName);
        else Hyprland.dispatch(Hyprland.usingLua ? `hl.plugin.hymission.workspace("${id}")` : `workspace ${id}`);
    }

    // The workspace/mission overview buttons: Hyprland has two plugins' worth of them, niri has one overview.
    function toggleOverview(hyprlandScript) {
        if (niri) NiriService.action(["toggle-overview"]);
        else Quickshell.execDetached([Quickshell.env("HOME") + "/bin/" + hyprlandScript]);
    }

    function refreshMonitors() {
        if (niri) NiriService.refreshOutputs();
        else Hyprland.refreshMonitors();
    }

    function refreshToplevels() {
        if (!niri) Hyprland.refreshToplevels();
    }

    // `hyprctl monitors -j` and `clients -j` shaped records for the recorder's target list.
    function recordMonitors() {
        return niri ? NiriService.recordMonitors() : Hyprland.monitors.values.map(monitor => monitor.lastIpcObject);
    }

    function recordClients() {
        return niri ? NiriService.recordClients() : Hyprland.toplevels.values.map(toplevel => toplevel.lastIpcObject);
    }

    // Opens `command` in a floating window of `width` x `height` centred on screen. Hyprland takes the rules
    // with the spawn itself; niri has no per-spawn rules, so NiriService floats the first window that
    // appears and matches `appIdHint`.
    function spawnFloating(command, width, height, appIdHint) {
        if (niri) {
            NiriService.spawnFloating(command, width, height, appIdHint);
            return;
        }
        const shellQuote = text => "'" + text.replace(/'/g, "'\\''") + "'";
        const joined = command.map(shellQuote).join(" ");
        const dispatch = "hl.dsp.exec_cmd(" + JSON.stringify(joined) + ", { float = true, center = true, size = '"
            + width + " " + height + "' })";
        Quickshell.execDetached(["hyprctl", "dispatch", dispatch]);
    }
}
