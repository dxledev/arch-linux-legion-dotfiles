import Quickshell
import Quickshell.Io
import "../core"
import "../island"

IpcHandler {
    target: "island"
    function brightness(): string {
        return JSON.stringify(BrightnessService.monitors.map(monitor => ({
            name: monitor.connector, label: monitor.label, brightness: monitor.brightness,
            supported: monitor.supported, initialized: monitor.initialized, error: monitor.error
        })));
    }
    function setBrightness(monitorName: string, percent: real): bool {
        const monitor = BrightnessService.getMonitor(monitorName);
        if (!monitor?.supported || !monitor.initialized || !Number.isFinite(percent) || percent < 0 || percent > 100) return false;
        monitor.setBrightness(percent);
        return true;
    }
    function nightlightEnabled(): bool { return NightLightService.enabled; }
    function toggleNightlight(): void { NightLightService.toggle(); }
    function ready(): bool { return ThemeService.ready; }
    function lock(): void { LockService.lock(); }
    function openPowerMenu(): void { IslandController.toggleMode(IslandState.powerMenuMode); }
    function openSystem(): void { IslandController.toggleMode(IslandState.systemMode); }
    function openAIUsage(): void { IslandController.toggleMode(IslandState.aiUsageMode); }
    function openKeybinds(): void { IslandController.toggleMode(IslandState.keybindsMode); }
    function openMediaControls(): void { IslandController.toggleMode(IslandState.mediaControlsMode); }
    function openExpandedHome(): void { IslandController.toggleExpandedHome(); }
    function toggleExpandedIsland(): void { IslandController.toggleMode(IslandState.expandedMode); }
    function reset(): void { IslandController.reset(); }
    function openWallpaperSelector(): void { IslandController.toggleMode(IslandState.wallpaperSelectorMode); }
    function openThemeSelector(): void { IslandController.toggleMode(IslandState.themeSelectorMode); }
    function openControlCenter(): void { IslandController.toggleMode(IslandState.controlCenterMode); }
    function openNotifications(): void { IslandController.toggleMode(IslandState.notificationsMode); }
    function openAudioDevices(): void { IslandController.toggleMode(IslandState.audioDevicesMode); }
    function openWifi(): void { IslandController.toggleMode(IslandState.wifiMode); }
    function openBluetooth(): void { IslandController.toggleMode(IslandState.bluetoothMode); }
    function openPowerProfile(): void { IslandController.toggleMode(IslandState.powerProfileMode); }
    function openProtonVpn(): void { IslandController.toggleMode(IslandState.protonVpnMode); }
    function sunshineEnabled(): bool { return SunshineService.running; }
    function toggleSunshine(): void { SunshineService.toggle(); }
    function openClipboard(): void { IslandController.toggleMode(IslandState.clipboardMode); }
    function openChromack(): void { IslandController.toggleMode(IslandState.chromackMode); }
    function openWallhaven(): void { IslandController.toggleMode(IslandState.wallhavenMode); }
    function openCalendar(): void { IslandController.toggleMode(IslandState.calendarMode, [IslandState.forecastMode]); }
    function toggleLyrics(): void { IslandController.toggleLyricsInIsland(); }
    function openNetworkSpeedTest(): void { IslandController.openNetworkSpeedTest(); }
    function openDiskSpeedTest(): void { IslandController.openDiskSpeedTest(); }
    function openLauncher(): void { IslandController.toggleMode(IslandState.launcherMode); }
    function openLibreOffice(): void { IslandController.toggleMode(IslandState.libreOfficeMode); }
    function openNavigation(): void { IslandController.toggleMode(IslandState.navigationMode); }
    function openClockSettings(): void { IslandController.toggleMode(IslandState.clockSettingsMode); }
    function openOsdSettings(): void { IslandController.toggleMode(IslandState.osdSettingsMode); }
    function openSettingsSection(section: string): void {
        IslandController.toggleSettingsSection(section);
    }
    function openDisplays(): void { IslandController.openDisplays(); }
    function closeDisplays(): void { DisplayService.close(); }
    function openSettings(): void {
        IslandController.toggleMode(IslandState.settingsMode, [
            IslandState.settingsSectionMode, IslandState.clockSettingsMode, IslandState.osdSettingsMode
        ]);
    }
    function openRecordOptions(): void { IslandController.toggleMode(IslandState.recordOptionsMode); }
    function recording(): bool { return RecorderService.running; }
    function stopRecording(): void { RecorderService.stop(); }
    function pauseRecording(): void { RecorderService.togglePause(); }
    // Keybind: stops the recording in progress, or opens the options for a new one.
    function toggleRecording(): void {
        if (RecorderService.running) RecorderService.stop();
        else IslandController.toggleMode(IslandState.recordOptionsMode);
    }
    function openTimer(): void { IslandController.toggleMode(IslandState.timerMode); }
    // Starts a countdown of the given length; keepAlert makes its alert stay until closed, and sound (one of the
    // panel's sound names such as "bell", or "" for silence) plays when it ends. Whether the alert offers Snooze, and
    // for how long, follows the panel.
    function startTimer(seconds: int, label: string, keepAlert: bool, sound: string): bool {
        return TimerService.start(seconds, label, keepAlert, sound);
    }
    function cancelTimers(): void { TimerService.cancelAll(); }
    // Pauses the running timers, or resumes them when they are all paused.
    function toggleTimerPause(): void { TimerService.toggleAllPaused(); }
    // Running timers, soonest first, as JSON: label, seconds left and whether the alert stays until closed.
    function timers(): string {
        return JSON.stringify(TimerService.timers.map(timer => ({
            id: timer.id, label: timer.label, remaining: TimerService.remainingSeconds(timer), paused: timer.paused, keepAlert: timer.indefinite, sound: timer.sound, snooze: timer.snooze
        })));
    }
    function openShellSwitcher(): void { if (Compositor.hasShellModes) IslandController.toggleMode(IslandState.shellSwitcherMode); }
    function openLayoutSwitcher(): void { IslandController.toggleMode(IslandState.layoutSwitcherMode); }
    function openWorkspaceAxis(): void { IslandController.toggleWorkspaceAxis(); }
    function nextWallpaper(): void { ThemeService.execute(["next"]); }
    function previousWallpaper(): void { ThemeService.execute(["previous"]); }
}
