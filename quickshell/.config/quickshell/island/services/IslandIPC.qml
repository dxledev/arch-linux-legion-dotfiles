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
    function openPowerMenu(): void { IslandController.toggleMode(IslandState.powerMenuMode); }
    function openExpandedHome(): void { IslandController.toggleMode(IslandState.expandedMode); }
    function reset(): void { IslandController.reset(); }
    function openWallpaperSelector(): void { IslandController.toggleMode(IslandState.wallpaperSelectorMode); }
    function openThemeSelector(): void { IslandController.toggleMode(IslandState.themeSelectorMode); }
    function openControlCenter(): void { IslandController.toggleMode(IslandState.controlCenterMode); }
    function openNotifications(): void { IslandController.toggleMode(IslandState.notificationsMode); }
    function openAudioDevices(): void { IslandController.toggleMode(IslandState.audioDevicesMode); }
    function openLauncher(): void { IslandController.toggleMode(IslandState.launcherMode); }
    function openNavigation(): void { IslandController.toggleMode(IslandState.navigationMode); }
    function openClockSettings(): void { IslandController.toggleMode(IslandState.clockSettingsMode); }
    function openOsdSettings(): void { IslandController.toggleMode(IslandState.osdSettingsMode); }
    function openSettingsSection(section: string): void {
        IslandController.toggleSettingsSection(section);
    }
    function openSettings(): void {
        IslandController.toggleMode(IslandState.settingsMode, [
            IslandState.settingsSectionMode, IslandState.clockSettingsMode, IslandState.osdSettingsMode
        ]);
    }
    function openShellSwitcher(): void { IslandController.toggleMode(IslandState.shellSwitcherMode); }
    function nextWallpaper(): void { ThemeService.execute(["next"]); }
    function previousWallpaper(): void { ThemeService.execute(["previous"]); }
}
