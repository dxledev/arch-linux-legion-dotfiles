function brightnessForScreen(events, screenName, islandScreens) {
    if (islandScreens.length === 1) return islandScreens[0].name === screenName ? events : [];
    return events.filter(event => event.monitorName === screenName);
}

function screensForSetting(screens, setting) {
    if (!setting || setting === "all" || setting === "automatic") return screens;
    const selected = screens.find(screen => screen.name === setting);
    return selected ? [selected] : screens.slice(0, 1);
}
