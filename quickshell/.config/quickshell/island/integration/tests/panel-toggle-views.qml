import QtQuick
import Quickshell
import "../../island"
import "../../core"
import "../../services"

ShellRoot {
    id: root
    property int phase: 0

    IslandIPC { id: ipc }

    function checkPanelToggles() {
        const panels = [
            ["openLauncher", IslandState.launcherMode],
            ["openExpandedHome", IslandState.expandedMode],
            ["openPowerMenu", IslandState.powerMenuMode],
            ["openControlCenter", IslandState.controlCenterMode],
            ["openNotifications", IslandState.notificationsMode],
            ["openAudioDevices", IslandState.audioDevicesMode],
            ["openThemeSelector", IslandState.themeSelectorMode],
            ["openWallpaperSelector", IslandState.wallpaperSelectorMode],
            ["openNavigation", IslandState.navigationMode],
            ["openClockSettings", IslandState.clockSettingsMode],
            ["openOsdSettings", IslandState.osdSettingsMode],
            ["openSettings", IslandState.settingsMode],
            ["openShellSwitcher", IslandState.shellSwitcherMode]
        ];
        for (const [method, mode] of panels) {
            IslandController.reset();
            ipc[method]();
            check(IslandState.mode === mode, method + " opens its panel");
            IslandState.panelMonitorName = "HDMI-A-1";
            IslandState.islandPinned = true;
            IslandState.returnToExpanded = true;
            ipc[method]();
            check(IslandState.mode === IslandState.defaultMode, method + " closes on second press");
            check(!IslandState.islandPinned && !IslandState.returnToExpanded, method + " clears pin and return state");
            check(IslandState.panelMonitorName === "", method + " clears panel ownership");
            ipc[method]();
            check(IslandState.mode === mode, method + " reopens on third press");
            IslandController.reset();
            IslandController.toggleMode(mode, [], "HDMI-A-1");
            IslandState.islandPinned = true;
            IslandState.returnToExpanded = true;
            IslandController.toggleMode(mode, [], "DP-1");
            check(IslandState.mode === mode, method + " opens on the other monitor");
            check(IslandState.panelMonitorName === "DP-1", method + " transfers panel ownership");
            check(!IslandState.islandPinned && !IslandState.returnToExpanded, method + " clears old monitor interaction state");
            IslandController.toggleMode(mode, [], "DP-1");
            check(IslandState.mode === IslandState.defaultMode, method + " closes on the new monitor");
        }
        for (const openSection of [
            () => IslandController.openClockSettings(),
            () => IslandController.openOsdSettings(),
            () => IslandController.openSettingsSection("appearance")
        ]) {
            openSection();
            ipc.openSettings();
            check(IslandState.mode === IslandState.defaultMode, "Settings shortcut closes its subpages");
        }
        ipc.openSettingsSection("appearance");
        ipc.openSettingsSection("clock");
        check(IslandState.settingsSection === "clock", "Different section navigates");
        ipc.openSettingsSection("clock");
        check(IslandState.mode === IslandState.defaultMode, "Same section closes");
        IslandController.openPowerMenu();
        IslandState.panelMonitorName = "HDMI-A-1";
        ipc.openNotifications();
        check(IslandState.mode === IslandState.notificationsMode, "Different shortcut switches panels");
        check(IslandState.panelMonitorName === "HDMI-A-1", "Switching panels retains their monitor");
        IslandController.toggleMode(IslandState.powerMenuMode, [], "DP-1");
        check(IslandState.mode === IslandState.powerMenuMode && IslandState.panelMonitorName === "DP-1",
            "Different shortcut transfers to its requested monitor");
        IslandController.toggleSettingsSection("appearance", "HDMI-A-1");
        IslandController.toggleSettingsSection("appearance", "DP-1");
        check(IslandState.mode === IslandState.settingsSectionMode && IslandState.panelMonitorName === "DP-1",
            "Same settings section transfers monitors");
        IslandController.toggleSettingsSection("clock", "HDMI-A-1");
        check(IslandState.settingsSection === "clock" && IslandState.panelMonitorName === "HDMI-A-1",
            "Different settings section transfers monitors");
        IslandController.toggleSettingsSection("invalid", "DP-1");
        check(IslandState.panelMonitorName === "HDMI-A-1", "Invalid section preserves the existing panel");
        IslandController.toggleMode(IslandState.settingsMode, [IslandState.settingsSectionMode], "DP-1");
        check(IslandState.mode === IslandState.settingsMode && IslandState.panelMonitorName === "DP-1",
            "Settings shortcut opens on another monitor from a subpage");
        IslandController.toggleMode(IslandState.settingsMode, [IslandState.settingsSectionMode], "DP-1");
        check(IslandState.mode === IslandState.defaultMode, "Settings shortcut closes on its owning monitor");
        IslandController.openNotifications();
        IslandController.openNotifications();
        check(IslandState.mode === IslandState.notificationsMode, "UI navigation remains an opener");
        IslandController.reset();
        console.log("PASS: all panel IPC toggles, pinned closure, settings subpages, switching, and UI navigation");
    }

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }

    IslandInteraction { id: interaction; monitorName: "HDMI-A-1" }

    Timer {
        interval: 160
        running: true
        repeat: true
        onTriggered: {
            try {
                if (!ThemeService.ready) return;
                if (root.phase === 0) {
                    root.checkPanelToggles();
                    ThemeService.settings = {hoverDelay: 80, collapseDelay: 80};
                    interaction.handleHoverChanged(true);
                    ipc.openExpandedHome();
                    ipc.openExpandedHome();
                    root.phase++;
                } else {
                    root.check(IslandState.mode === IslandState.defaultMode, "Pending hover does not reopen a closed panel");
                    console.log("PASS: panel toggles and pending hover cancellation");
                    Qt.quit();
                }
            } catch (error) {
                console.error("FAIL: " + error);
                Qt.quit();
            }
        }
    }
}
