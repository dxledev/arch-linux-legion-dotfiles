pragma Singleton
import QtQuick
import Quickshell
import "../island"
import "MenuEntries.js" as MenuEntries
import "WorkspacePresentation.js" as WorkspacePresentation

Singleton {
    id: root
    property var pendingPinnedIds: null
    property var randomizedIds: []
    property bool workspaceAxisVisibilityValidated: false
    readonly property int rows: MenuEntries.gridSize(ThemeService.settings.menuRows)
    readonly property int columns: MenuEntries.gridSize(ThemeService.settings.menuColumns)
    readonly property int cardLimit: rows * columns
    readonly property var pinnedIds: pendingPinnedIds ?? MenuEntries.sanitizePinnedIds(ThemeService.settings.menuPinnedEntries)
    readonly property var availableEntries: WorkspacePresentation.availableMenuEntries(MenuEntries.menuEntries,
        workspaceAxisVisibilityValidated, WorkspacePresentationService.canOpenAxis
            && !WorkspacePresentationService.actionPending)
    readonly property var availableIds: availableEntries.map(entry => entry.id)
    readonly property var visiblePinnedIds: MenuEntries.sanitizePinnedIds(pinnedIds, availableEntries)
    readonly property bool workspaceAxisStatusError: IslandState.mode === IslandState.navigationMode
        && !WorkspacePresentationService.statusKnown && WorkspacePresentationService.error.length > 0
    readonly property var displayedIds: MenuEntries.listDisplayedIds(visiblePinnedIds,
        WorkspacePresentation.filterAvailableIds(randomizedIds, availableIds), availableIds)

    function beginOpen() {
        workspaceAxisVisibilityValidated = false
        randomizedIds = MenuEntries.shuffleIds(MenuEntries.browsableIds());
        WorkspacePresentationService.refresh()
    }

    function retryWorkspaceAxisStatus() {
        workspaceAxisVisibilityValidated = false
        WorkspacePresentationService.refresh()
    }

    function isPinned(id) {
        return visiblePinnedIds.includes(id);
    }

    function togglePin(id) {
        if (!ThemeService.ready || !MenuEntries.findEntryById(id, availableEntries)) return false;
        const pins = pinnedIds.slice();
        const index = pins.indexOf(id);
        if (index >= 0) pins.splice(index, 1);
        else if (visiblePinnedIds.length < cardLimit && pins.length < MenuEntries.maximumPins) pins.push(id);
        else return false;
        pendingPinnedIds = pins;
        ThemeService.setSetting("menuPinnedEntries", JSON.stringify(pins));
        return true;
    }

    function movePin(id, toIndex) {
        if (!ThemeService.ready) return false;
        const visiblePins = MenuEntries.movePinnedId(visiblePinnedIds, id, toIndex);
        if (JSON.stringify(visiblePins) === JSON.stringify(visiblePinnedIds)) return false;
        const pins = pinnedIds.slice();
        const visibleSlots = [];
        for (let index = 0; index < pins.length; index++) {
            if (availableIds.includes(pins[index])) visibleSlots.push(index);
        }
        for (let index = 0; index < visibleSlots.length; index++)
            pins[visibleSlots[index]] = visiblePins[index];
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
        target: WorkspacePresentationService
        function onStatusRefreshed(succeeded) {
            if (IslandState.mode === IslandState.navigationMode)
                root.workspaceAxisVisibilityValidated = succeeded;
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
