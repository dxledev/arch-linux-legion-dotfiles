pragma Singleton
import QtQuick
import Quickshell
import "../island"
import "MenuEntries.js" as MenuEntries

Singleton {
    id: root
    property var pendingPinnedIds: null
    property var randomizedIds: []
    readonly property int rows: MenuEntries.gridSize(ThemeService.settings.menuRows)
    readonly property int columns: MenuEntries.gridSize(ThemeService.settings.menuColumns)
    readonly property int cardLimit: rows * columns
    readonly property var pinnedIds: pendingPinnedIds ?? MenuEntries.sanitizePinnedIds(ThemeService.settings.menuPinnedEntries)
    readonly property var displayedIds: MenuEntries.chooseDisplayedIds(pinnedIds, randomizedIds, cardLimit, undefined, false)

    function beginOpen() {
        randomizedIds = MenuEntries.shuffleIds(MenuEntries.menuEntries.map(entry => entry.id));
    }

    function isPinned(id) {
        return pinnedIds.includes(id);
    }

    function togglePin(id) {
        if (!ThemeService.ready || !MenuEntries.findEntryById(id)) return false;
        const pins = pinnedIds.slice();
        const index = pins.indexOf(id);
        if (index >= 0) pins.splice(index, 1);
        else if (pins.length < cardLimit) pins.push(id);
        else return false;
        pendingPinnedIds = pins;
        ThemeService.setSetting("menuPinnedEntries", JSON.stringify(pins));
        return true;
    }

    function movePin(id, toIndex) {
        if (!ThemeService.ready) return false;
        const pins = MenuEntries.movePinnedId(pinnedIds, id, toIndex);
        if (JSON.stringify(pins) === JSON.stringify(pinnedIds)) return false;
        pendingPinnedIds = pins;
        ThemeService.setSetting("menuPinnedEntries", JSON.stringify(pins));
        return true;
    }

    Connections {
        target: IslandState
        function onModeChanged() {
            if (IslandState.mode === IslandState.navigationMode) root.beginOpen();
        }
    }
    Connections {
        target: ThemeService
        function onSettingsChanged() {
            const savedPins = MenuEntries.sanitizePinnedIds(ThemeService.settings.menuPinnedEntries);
            if (!ThemeService.busy && ThemeService.pending.length === 0
                && JSON.stringify(savedPins) === JSON.stringify(root.pendingPinnedIds))
                root.pendingPinnedIds = null;
        }
        function onErrorChanged() {
            if (ThemeService.error) root.pendingPinnedIds = null;
        }
    }
    Component.onCompleted: beginOpen()
}
