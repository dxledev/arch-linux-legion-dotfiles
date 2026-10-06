function osdMonitorName(sourceMonitor, islandScreens) {
    return islandScreens.find(screen => screen.name === sourceMonitor)?.name
        ?? islandScreens.find(screen => screen.name)?.name ?? sourceMonitor;
}

function screensForSetting(screens, setting) {
    if (!setting || setting === "all" || setting === "automatic") return screens;
    const selected = screens.find(screen => screen.name === setting);
    return selected ? [selected] : screens.slice(0, 1);
}
