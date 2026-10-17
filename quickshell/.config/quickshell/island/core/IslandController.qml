pragma Singleton

import QtQuick

import "../island"
import "../services"
import "../services/MenuEntries.js" as MenuEntries
import "../services/WorkspacePresentation.js" as WorkspacePresentation

QtObject {
    id: root
    property int workspaceAxisRequestGeneration: 0
    property var workspaceAxisRequest: WorkspacePresentation.cancelOpenRequest(0)
    readonly property bool workspaceAxisOpenPending: workspaceAxisRequest.pending
    property bool workspaceAxisModeAuthorized: false

    property Connections workspacePresentationConnections: Connections {
        target: WorkspacePresentationService
        function onStatusRefreshed(succeeded) {
            if (!root.workspaceAxisOpenPending)
                return
            const decision = WorkspacePresentation.resolveOpenRequest(root.workspaceAxisRequest,
                root.workspaceAxisRequestGeneration, IslandState.mode, succeeded,
                WorkspacePresentationService.canOpenAxis, WorkspacePresentationService.actionPending)
            root.cancelWorkspaceAxisRequest()
            if (decision.allowed) {
                root.workspaceAxisModeAuthorized = true
                root.setMode(IslandState.workspaceAxisMode, decision.monitorName)
            }
        }
        function onCanOpenAxisChanged() {
            if (!WorkspacePresentationService.canOpenAxis && IslandState.mode === IslandState.workspaceAxisMode)
                root.reset()
        }
    }

    property Connections islandModeConnections: Connections {
        target: IslandState
        function onModeChanged() {
            if (root.workspaceAxisOpenPending && IslandState.mode !== root.workspaceAxisRequest.mode)
                root.cancelWorkspaceAxisRequest()
        }
    }

    // The folder picker for recordings opens its own window, so the settings panel folds away while it is up and
    // comes back, on the same monitor, once it closes (unless something else has been opened meanwhile).
    property string folderPickerReturnSection: ""
    property string folderPickerReturnMonitor: ""
    property Connections recorderFolderPickerConnections: Connections {
        target: RecorderService
        function onDirectoryPickerOpening() {
            const inSettings = IslandState.mode === IslandState.settingsSectionMode && IslandState.settingsSection === "screenRecording"
            root.folderPickerReturnSection = inSettings ? IslandState.settingsSection : ""
            root.folderPickerReturnMonitor = IslandState.panelMonitorName
            if (inSettings) root.reset()
        }
        function onDirectoryPickerClosed() {
            const section = root.folderPickerReturnSection
            root.folderPickerReturnSection = ""
            if (section === "" || IslandState.mode !== IslandState.defaultMode) return
            IslandState.settingsSection = section
            root.setMode(IslandState.settingsSectionMode, root.folderPickerReturnMonitor)
        }
    }

    readonly property var settingsSections: MenuEntries.settingsSections.map(section => section.key)

    function openMenuEntry(id) {
        const entry = MenuEntries.findEntryById(id);
        if (!entry) return;
        if (entry.route.type === "settings") openSettingsSection(entry.route.section);
        else if (typeof root[entry.route.action] === "function") root[entry.route.action]();
    }

    function focusedPanelMonitorName() {
        const screen = ThemeService.islandScreens.find(screen => screen.name === Compositor.focusedMonitorName)
            ?? ThemeService.islandScreens[0]
        return screen?.name || ""
    }

    function setMode(mode, monitorName) {
        if (mode === IslandState.workspaceAxisMode
                && (!workspaceAxisModeAuthorized || !WorkspacePresentationService.canOpenAxis))
            return false
        if (mode === IslandState.calendarMode && IslandState.mode !== IslandState.calendarMode
                && IslandState.mode !== IslandState.forecastMode) {
            IslandState.calendarReturnMode = IslandState.mode === IslandState.expandedMode
                ? IslandState.expandedMode : IslandState.navigationMode
        }
        if (mode === IslandState.systemMode && IslandState.mode !== IslandState.systemMode) {
            IslandState.systemReturnMode = IslandState.mode === IslandState.powerMenuMode
                ? IslandState.powerMenuMode : IslandState.navigationMode
        }
        if (mode === IslandState.defaultMode) {
            IslandState.panelMonitorName = ""
        } else if (IslandState.mode === IslandState.defaultMode || !IslandState.panelMonitorName) {
            IslandState.panelMonitorName = monitorName || focusedPanelMonitorName()
        }
        // Lyrics in the clock only survive the island's own compact <-> expanded hover hops, and
        // only a panel opening on that same island takes them away; another monitor's is left alone.
        if (mode !== IslandState.defaultMode && mode !== IslandState.expandedMode
                && IslandState.lyricsClockMonitor === IslandState.panelMonitorName)
            IslandState.lyricsClockMonitor = ""
        IslandState.mode = mode
        if (mode === IslandState.workspaceAxisMode)
            workspaceAxisModeAuthorized = false
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
        if (!Compositor.hasDisplayEditor) return
        DisplayService.open()
        reset()
    }

    function openSettings() { setMode(IslandState.settingsMode) }
    function openClockSettings() { setMode(IslandState.clockSettingsMode) }
    function openOsdSettings() { setMode(IslandState.osdSettingsMode) }

    function openShellSwitcher() { if (Compositor.hasShellModes) setMode(IslandState.shellSwitcherMode) }
    function openLayoutSwitcher() { if (Compositor.hasLayoutControls) setMode(IslandState.layoutSwitcherMode) }

    function cancelWorkspaceAxisRequest() {
        workspaceAxisRequestGeneration += 1
        workspaceAxisRequest = WorkspacePresentation.cancelOpenRequest(workspaceAxisRequestGeneration)
        workspaceAxisModeAuthorized = false
    }

    function openWorkspaceAxis(monitorName = IslandState.panelMonitorName || focusedPanelMonitorName()) {
        if (!Compositor.hasLayoutControls) return
        if (workspaceAxisOpenPending || IslandState.mode === IslandState.workspaceAxisMode)
            return
        workspaceAxisRequestGeneration += 1
        workspaceAxisRequest = WorkspacePresentation.createOpenRequest(
            workspaceAxisRequestGeneration, IslandState.mode, monitorName)
        WorkspacePresentationService.refresh()
    }

    function toggleWorkspaceAxis() {
        const monitorName = focusedPanelMonitorName()
        preparePanelToggle(monitorName)
        if (IslandState.mode === IslandState.workspaceAxisMode) {
            cancelWorkspaceAxisRequest()
            reset()
            return
        }
        if (workspaceAxisOpenPending) {
            cancelWorkspaceAxisRequest()
            return
        }
        openWorkspaceAxis(monitorName)
    }

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

    function backFromSystem() { setMode(IslandState.systemReturnMode) }

    function openAIUsage() { setMode(IslandState.aiUsageMode) }

    function openKeybinds() { if (Compositor.hasKeybindList) setMode(IslandState.keybindsMode) }

    function openControlCenter() {
        setMode(IslandState.controlCenterMode)
    }

    function openNotifications() {
        setMode(IslandState.notificationsMode)
    }

    function openAudioDevices() {
        setMode(IslandState.audioDevicesMode)
    }

    function openWifi() { setMode(IslandState.wifiMode) }
    function openBluetooth() { setMode(IslandState.bluetoothMode) }
    function openPowerProfile() { setMode(IslandState.powerProfileMode) }
    function openProtonVpn() { setMode(IslandState.protonVpnMode) }
    function openLauncherSubmenu(submenu) { if (submenu === "libreoffice") setMode(IslandState.libreOfficeMode) }
    // The options popup for a new recording. Back returns to the expanded island with its workspace section open.
    function openRecordOptions() { setMode(IslandState.recordOptionsMode) }
    function closeRecordOptions() {
        openExpanded()
        IslandState.workspacePanelOpen = true
    }
    function openTimer() { setMode(IslandState.timerMode) }
    function openClipboard() { setMode(IslandState.clipboardMode) }
    function openChromack() { setMode(IslandState.chromackMode) }
    function openWallhaven() { setMode(IslandState.wallhavenMode) }
    function openCalendar() { setMode(IslandState.calendarMode) }
    function backFromCalendar() { setMode(IslandState.calendarReturnMode) }
    // The Calendar hands over its selected day, quote and card height: Back restores the first two and
    // the Forecast matches the third.
    function openForecast(dateKey, quote, cardHeight) {
        IslandState.calendarSelectedKey = dateKey || ""
        IslandState.calendarQuote = quote || null
        IslandState.calendarCardHeight = cardHeight || 0
        setMode(IslandState.forecastMode)
    }
    function backFromForecast() { setMode(IslandState.calendarMode) }

    signal wifiQrRequested(string ssid, string iface, string monitorName)

    // Closes the panel and shows the QR overlay on the panel's monitor.
    function openWifiQr(ssid, iface) {
        const monitorName = IslandState.panelMonitorName || focusedPanelMonitorName()
        reset()
        wifiQrRequested(ssid, iface, monitorName)
    }

    signal speedTestRequested(string kind, string monitorName)

    // Closes the panel and runs a speed test overlay on the panel's monitor.
    function openSpeedTest(kind) {
        const monitorName = IslandState.panelMonitorName || focusedPanelMonitorName()
        reset()
        speedTestRequested(kind, monitorName)
    }

    function openNetworkSpeedTest() { openSpeedTest("network") }

    function openDiskSpeedTest() { openSpeedTest("disk") }

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

    // The lyrics card floats under the island and outlives every island mode, so
    // reset() and setMode() leave it alone. Only closeLyrics() (the card's close button) clears it.
    function openLyrics(monitorName = IslandState.panelMonitorName || focusedPanelMonitorName()) {
        IslandState.lyricsMonitorName = monitorName
        IslandState.lyricsOpen = true
        // Lyrics live on one island at a time: asking for them on another one moves them there.
        if (IslandState.lyricsClockMonitor !== "" && IslandState.lyricsClockMonitor !== monitorName)
            IslandState.lyricsClockMonitor = ""
    }

    function closeLyrics() {
        IslandState.lyricsOpen = false
        IslandState.lyricsExpanded = false
    }

    // Moves the lyrics from the floating card into the island: the clock gives way to the current
    // line, the card closes and any open panel (media included) folds away.
    function showLyricsInIsland(monitorName = IslandState.lyricsMonitorName || focusedPanelMonitorName()) {
        closeLyrics()
        reset()
        IslandState.lyricsClockMonitor = monitorName
    }

    function closeLyricsInIsland() {
        IslandState.lyricsClockMonitor = ""
    }

    // Keybind toggle: lyrics in the island's clock on the focused monitor, or back to the clock.
    // Turning them on needs a player, since nothing would show and the request would linger.
    function toggleLyricsInIsland(monitorName = focusedPanelMonitorName()) {
        if (IslandState.lyricsClockMonitor !== "")
            closeLyricsInIsland()
        else if (MediaService.hasPlayer)
            showLyricsInIsland(monitorName)
    }

    function toggleLyricsExpanded() {
        IslandState.lyricsExpanded = !IslandState.lyricsExpanded
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

        IslandState.awaitingMediaHover = true
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
        cancelWorkspaceAxisRequest()
        IslandState.ignoreNextIslandTap = false
        IslandState.returnToExpanded = false
        IslandState.islandPinned = false
        setMode(IslandState.defaultMode)
    }

    Component.onCompleted: WorkspacePresentationService.refresh()
}
