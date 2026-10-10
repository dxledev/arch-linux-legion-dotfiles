pragma Singleton

import QtQuick
import Quickshell.Hyprland

import "../island"
import "../services"
import "../services/MenuEntries.js" as MenuEntries

QtObject {
    id: root

    readonly property var settingsSections: MenuEntries.settingsSections.map(section => section.key)

    function openMenuEntry(id) {
        const entry = MenuEntries.findEntryById(id);
        if (!entry) return;
        if (entry.route.type === "settings") openSettingsSection(entry.route.section);
        else if (typeof root[entry.route.action] === "function") root[entry.route.action]();
    }

    function focusedPanelMonitorName() {
        const screen = ThemeService.islandScreens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
            ?? ThemeService.islandScreens[0]
        return screen?.name || ""
    }

    function setMode(mode, monitorName) {
        if (mode === IslandState.defaultMode) {
            IslandState.panelMonitorName = ""
        } else if (IslandState.mode === IslandState.defaultMode || !IslandState.panelMonitorName) {
            IslandState.panelMonitorName = monitorName || focusedPanelMonitorName()
        }
        IslandState.mode = mode
    }

    function preparePanelToggle(monitorName) {
        if (monitorName && IslandState.panelMonitorName && IslandState.panelMonitorName !== monitorName)
            reset()
    }

    function toggleMode(mode, relatedModes = [], monitorName = focusedPanelMonitorName()) {
        preparePanelToggle(monitorName)
        if (IslandState.mode === mode || relatedModes.includes(IslandState.mode)) {
            reset()
        } else {
            setMode(mode, monitorName)
        }
    }

    function toggleSettingsSection(section, monitorName = focusedPanelMonitorName()) {
        if (!settingsSections.includes(section)) return
        if (section === "displays") {
            openDisplays()
            return
        }
        preparePanelToggle(monitorName)
        if (IslandState.mode === IslandState.settingsSectionMode && IslandState.settingsSection === section) {
            reset()
        } else {
            IslandState.settingsSection = section
            setMode(IslandState.settingsSectionMode, monitorName)
        }
    }

    // =========================================================
    // NAVIGATION
    // Open a specific island view/mode.
    // =========================================================

    function openNavigation() {
        ignoreNextIslandTap();
        setMode(IslandState.navigationMode);
    }

    function openSettingsSection(section) {
        if (!settingsSections.includes(section)) return
        if (section === "displays") {
            openDisplays()
            return
        }
        IslandState.settingsSection = section
        setMode(IslandState.settingsSectionMode)
    }

    function openLauncher() { setMode(IslandState.launcherMode) }

    function openDisplays() {
        DisplayService.open()
        reset()
    }

    function openSettings() { setMode(IslandState.settingsMode) }
    function openClockSettings() { setMode(IslandState.clockSettingsMode) }
    function openOsdSettings() { setMode(IslandState.osdSettingsMode) }

    function openShellSwitcher() { setMode(IslandState.shellSwitcherMode) }

    function openDefault() {
        setMode(IslandState.defaultMode)
    }

    function openExpanded(monitorName) {
        setMode(IslandState.expandedMode, monitorName)
    }

    function openPowerMenu() {
        setMode(IslandState.powerMenuMode)
    }

    function openSystem() { setMode(IslandState.systemMode) }

    function openControlCenter() {
        setMode(IslandState.controlCenterMode)
    }

    function openNotifications() {
        setMode(IslandState.notificationsMode)
    }

    function openAudioDevices() {
        setMode(IslandState.audioDevicesMode)
    }

    function openThemeSelector() {
        setMode(IslandState.themeSelectorMode)
    }

    function openWallpaperSelector() {
        setMode(IslandState.wallpaperSelectorMode)
    }

    function openMediaControls() {
        ignoreNextIslandTap()

        IslandState.islandPinned = true

        setMode(IslandState.mediaControlsMode)
    }

    // =========================================================
    // CONTEXTUAL NAVIGATION
    // Open views from specific parts of the island while
    // preserving the current interaction state.
    // =========================================================

    function openMediaFromLeftSection() {
        ignoreNextIslandTap()

        IslandState.returnToExpanded =
            IslandState.islandPinned

        IslandState.islandPinned = false

        setMode(IslandState.mediaControlsMode)
    }

    function openControlCenterFromRightSection() {
        IslandState.returnToExpanded =
            IslandState.islandPinned

        IslandState.islandPinned = false

        setMode(IslandState.controlCenterMode)
    }

    function openPowerMenuFromRightSection() {
        IslandState.returnToExpanded = IslandState.islandPinned
        IslandState.islandPinned = false
        setMode(IslandState.powerMenuMode)
    }


    // =========================================================
    // INTERACTION
    // Small state changes caused by direct island interaction.
    // =========================================================

    function ignoreNextIslandTap() {
        IslandState.ignoreNextIslandTap = true

        Qt.callLater(function() {
            IslandState.ignoreNextIslandTap = false
        })
    }

    function clearIgnoredTap() {
        IslandState.ignoreNextIslandTap = false
    }

    function togglePin() {
        IslandState.islandPinned =
            !IslandState.islandPinned
    }

    function restoreExpanded() {
        IslandState.islandPinned = true
        IslandState.returnToExpanded = false

        openExpanded()
    }


    // =========================================================
    // RESET
    // Return the island to its normal initial state.
    // =========================================================

    function reset() {
        IslandState.ignoreNextIslandTap = false
        IslandState.returnToExpanded = false
        IslandState.islandPinned = false
        setMode(IslandState.defaultMode)
    }
}
