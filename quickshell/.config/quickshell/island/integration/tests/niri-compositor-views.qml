import QtQuick
import Quickshell
import "../../core"
import "../../island"
import "../../services"

// Drives Compositor and NiriService against the mock `niri` of the niri-compositor test.
ShellRoot {
    id: root
    property int phase: 0
    property int elapsed: 0

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }
    function ids(entries) { return JSON.stringify(entries.map(entry => entry.id)); }
    function tick() {
        elapsed += 40;
        if (elapsed > 9000) throw new Error("Timed out in phase " + phase);
        switch (phase) {
        case 0: {
            if (!NiriService.connected || Compositor.workspaces.length !== 3 || Object.keys(NiriService.outputs).length !== 2) return;
            check(Compositor.niri, "niri is detected");
            check(Compositor.name === "niri", "Compositor name");
            check(Compositor.focusedMonitorName === "HDMI-A-1", "Focused monitor from the focused workspace: " + Compositor.focusedMonitorName);
            check(Compositor.focusedWorkspace.id === 1, "Focused workspace number is the index on its monitor");
            const own = WorkspaceService.workspacesForMonitor(Compositor.workspaces, "HDMI-A-1", false);
            check(ids(WorkspaceService.workspaceEntries(own, null, true, 11, 1)) === "[1,2]",
                "Only existing workspaces are listed, not the persistent count: " + ids(WorkspaceService.workspaceEntries(own, null, true, 11, 1)));
            check(WorkspaceService.workspaceEntries(own, null, true, 11, 1).every(entry => entry.occupied), "Occupancy comes from the window counts");
            const everything = WorkspaceService.workspaceEntries(Compositor.workspaces, null, false, 11, 1);
            check(ids(everything) === "[1,2]", "Equal indexes on two monitors share one entry: " + ids(everything));
            check(WorkspaceService.specialEntries(Compositor.workspaces, Compositor.toplevels, [], "").length === 0, "No special workspaces");
            const monitor = Compositor.monitorFor({name: "DP-1"});
            check(monitor.activeWorkspace.id === 1 && monitor.name === "DP-1", "Monitor lookup by screen");
            check(Compositor.monitorFor({name: "nowhere"}) === null, "Unknown screen");
            check(Compositor.hasFullscreen(monitor) === false, "No fullscreen toplevels");
            check(Compositor.recordMonitors().length === 2, "Recorder monitors");
            check(JSON.stringify(Compositor.recordClients().map(client => client.address)) === "[\"7\"]", "Recorder windows: " + JSON.stringify(Compositor.recordClients()));
            check(NiriService.keyboardLayoutName === "English (US)", "Keyboard layout from the stream");
            for (const hidden of ["layout", "keybinds", "workspace-axis", "shell-mode"])
                check(!MenuService.availableIds.includes(hidden), "Hyprland-only menu entry hidden on niri: " + hidden);
            check(MenuService.availableIds.includes("themes") && MenuService.availableIds.includes("wallpapers"), "Other menu entries stay");
            check(!Compositor.hasShellModes && !Compositor.hasLayoutControls && !Compositor.hasDisplayEditor && !Compositor.hasKeybindList && !Compositor.hasNightLight, "Hyprland-only features are gated");
            check(!NightLightService.available && NightLightService.subtitle === "Unavailable", "Night light reports unavailable");
            elapsed = 0;
            phase++;
            break;
        }
        case 1:
            // The mock moves the focus to the other monitor and switches the layout.
            if (Compositor.focusedMonitorName !== "DP-1") return;
            check(NiriService.keyboardLayoutName === "Persian", "Layout switch event: " + NiriService.keyboardLayoutName);
            Compositor.spawnFloating(["/usr/bin/touch", Quickshell.env("NIRI_TEST_TRIGGER")], 1200, 800, "omafiles");
            elapsed = 0;
            phase++;
            break;
        case 2:
            // The mock opens windows once the spawn ran; give the float actions time to be logged.
            if (elapsed < 1500) return;
            console.log("PASS: niri compositor service");
            Qt.quit();
        }
    }

    Timer {
        interval: 40
        running: true
        repeat: true
        onTriggered: {
            try { root.tick(); }
            catch (error) { console.error("FAIL: phase " + root.phase + ": " + error); Qt.quit(); }
        }
    }
}
