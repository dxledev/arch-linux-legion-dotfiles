import QtQuick
import QtTest
import Quickshell
import "../../views"
import "../../services"
import "../../core"
import "../../island"
import "../../services/MenuEntries.js" as MenuEntries

ShellRoot {
    id: root
    property int phase: 0
    property int pinIndex: 0
    property var randomizedAtOpen: null
    property string pendingId: ""
    property var pinChoices: ["themes", "wallpapers", "settings", "shell-mode"]
    property var nextPins: [
        ["themes"],
        ["themes", "wallpapers"],
        ["themes", "wallpapers", "settings"],
        ["themes", "wallpapers", "settings", "shell-mode"]
    ]
    property var inlineSections: ["launcher", "appearance", "clock", "lock", "osd", "workspaces", "dynamicPalette", "notifications", "interaction", "wallpaperAnimation"]
    property var controllerRoutes: [
        ["session", IslandState.powerMenuMode],
        ["control-center", IslandState.controlCenterMode],
        ["audio-devices", IslandState.audioDevicesMode],
        ["shell-mode", IslandState.shellSwitcherMode]
    ]
    property int routeIndex: 0

    function check(condition, message) { if (!condition) throw new Error(message); }
    function named(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const found = named(child, name);
            if (found) return found;
        }
        return null;
    }
    function click(item) {
        check(item, "Pointer target exists");
        check(input.mouseClick(item, item.width / 2, item.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Deliver pointer click");
    }
    function card(view, id) { return named(view, "menu-entry-" + id); }
    function pinButton(view, id) { return named(card(view, id), "navigation-card-pin"); }
    function openMenu() {
        IslandController.openNavigation();
        check(IslandState.mode === IslandState.navigationMode, "Menu opened");
    }
    function startSearch(view) {
        const search = named(view, "menu-search");
        if (!view.searchVisible) click(named(view, "panel-title-action"));
        else search.forceActiveFocus();
        check(view.searchVisible && search.activeFocus, "Search opens and receives focus");
        return search;
    }
    function queryFor(id) {
        const entry = MenuEntries.findEntryById(id);
        return entry.title + " " + entry.subtitle;
    }
    function setQuery(view, id) {
        startSearch(view).text = queryFor(id);
    }
    function openPendingRoute(id) {
        openMenu();
        setQuery(menu, id);
        pendingId = id;
        phase = 80;
    }
    function testRoutes() {
        if (routeIndex < inlineSections.length) {
            openPendingRoute("settings-" + inlineSections[routeIndex]);
            return;
        }
        if (routeIndex === inlineSections.length) {
            const displays = MenuEntries.findEntryById("settings-displays");
            check(displays.route.type === "settings" && displays.route.section === "displays", "Displays registry route points to display settings");
            check(IslandController.settingsSections.includes("displays"), "Displays is registered without launching the daemon");
            routeIndex++;
            return;
        }
        const index = routeIndex - inlineSections.length - 1;
        if (index < controllerRoutes.length) {
            openPendingRoute(controllerRoutes[index][0]);
            return;
        }
        phase = 90;
    }
    function finishRoute() {
        click(card(menu, pendingId));
        phase = 81;
    }
    function tick() {
        if (!ThemeService.ready || ThemeService.busy) return;
        if (phase === 0) {
            check(ThemeService.settings.menuPinnedEntries.length === 0, "Fixture starts without saved pins");
            openMenu();
            check(menu.entries.length === 4, "Closed menu shows four cards");
            phase = 1;
        } else if (phase === 1) {
            check(menu.implicitHeight === 392 && menu.height === 392, "Menu is 392 px tall when search is closed: " + menu.height);
            const grid = named(menu, "menu-grid");
            check(grid.height === 276, "Menu card grid keeps its height");
            check(grid.contentHeight === grid.height && grid.contentY === 0, "Four cards do not create blank scroll space");
            const firstCard = card(menu, menu.entries[0].id);
            const secondColumnCard = card(menu, menu.entries[1].id);
            check(firstCard && firstCard.height === 132, "Navigation cards are 132 px tall");
            check(firstCard.width === 200 && secondColumnCard.width === 200, "Menu cards use two 200 px columns");
            check(secondColumnCard.x - firstCard.x === 212, "Menu cards have a 12 px column gap");
            check(firstCard.background.radius === 26, "Navigation cards keep 26 px corners");
            check(JSON.stringify(secondMenu.entries.map(entry => entry.id)) === JSON.stringify(menu.entries.map(entry => entry.id)), "Both views display the same randomized choices");
            randomizedAtOpen = MenuService.randomizedIds;
            click(named(menu, "panel-title-action"));
            check(menu.searchVisible && named(menu, "menu-search").activeFocus, "Search action focuses the search field");
            phase = 2;
        } else if (phase === 2) {
            check(menu.height === 452, "Open search adds 60 px to menu height: " + menu.height);
            check(menu.entries.length === 22, "Empty query shows all 22 entries");
            named(menu, "menu-search").text = "session";
            phase = 3;
        } else if (phase === 3) {
            check(menu.entries.length === 1 && menu.entries[0].id === "session", "Session search result is correct");
            check(MenuService.randomizedIds === randomizedAtOpen, "Search does not change the open menu order");
            click(named(menu, "panel-title-action"));
            phase = 4;
        } else if (phase === 4) {
            check(!menu.searchVisible && menu.height === 392, "Search action hides the field and restores menu height");
            check(MenuService.randomizedIds === randomizedAtOpen, "Closing search keeps the cached order");
            startSearch(menu).text = "session";
            phase = 5;
        } else if (phase === 5) {
            const search = named(menu, "menu-search");
            check(menu.entries.length === 1 && menu.entries[0].id === "session", "Keyboard route search result is present");
            search.forceActiveFocus();
            input.keyClick(Qt.Key_Down, Qt.NoModifier, 0);
            check(named(menu, "menu-grid").activeFocus, "Down moves focus from search to cards");
            input.keyClick(Qt.Key_Enter, Qt.NoModifier, 0);
            check(IslandState.mode === IslandState.powerMenuMode, "Enter opens the highlighted Session route");
            IslandController.reset();
            phase = 6;
        } else if (phase === 6) {
            openMenu();
            randomizedAtOpen = MenuService.randomizedIds;
            startSearch(menu).text = "session";
            phase = 7;
        } else if (phase === 7) {
            input.keyClick(Qt.Key_Escape, Qt.NoModifier, 0);
            check(!menu.searchVisible && named(menu, "menu-search").text === "", "Escape clears and hides search first");
            phase = 8;
        } else if (phase === 8) {
            input.keyClick(Qt.Key_Escape, Qt.NoModifier, 0);
            check(IslandState.mode === IslandState.defaultMode, "Second Escape closes the menu");
            openMenu();
            check(MenuService.randomizedIds !== randomizedAtOpen, "Reentry initializes a fresh randomized order");
            randomizedAtOpen = MenuService.randomizedIds;
            setQuery(menu, pinChoices[pinIndex]);
            phase = 9;
        } else if (phase === 9) {
            const id = pinChoices[pinIndex];
            check(menu.entries.length === 1 && menu.entries[0].id === id, "Pin target is filtered to one card");
            const targetPin = pinButton(menu, id);
            click(targetPin);
            check(MenuService.isPinned(id) && IslandState.mode === IslandState.navigationMode, "Pin toggles optimistically while staying in Menu");
            check(targetPin.Accessible.checked && targetPin.iconSource.toString().includes("pin-filled.svg"), "Pinned card uses filled pin and checked state");
            check(JSON.stringify(MenuService.pinnedIds) === JSON.stringify(nextPins[pinIndex]), "Pin choice order is retained");
            check(JSON.stringify(secondMenu.entries.map(entry => entry.id)) === JSON.stringify(MenuService.displayedIds), "Second view follows shared displayed choices");
            pinIndex++;
            phase = 10;
        } else if (phase === 10) {
            const expected = nextPins[pinIndex - 1];
            if (ThemeService.settings.menuPinnedEntries.length !== expected.length) return;
            check(JSON.stringify(ThemeService.settings.menuPinnedEntries) === JSON.stringify(expected), "Optimistic pins reconcile with saved settings");
            check(MenuService.pendingPinnedIds === null, "Successful settings write clears optimistic pins");
            if (pinIndex < pinChoices.length) {
                setQuery(menu, pinChoices[pinIndex]);
                phase = 9;
            } else {
                setQuery(menu, "control-center");
                phase = 11;
            }
        } else if (phase === 11) {
            check(menu.entries.length === 1 && menu.entries[0].id === "control-center", "Fifth pin candidate is visible");
            const fifthPin = pinButton(menu, "control-center");
            check(!fifthPin.enabled, "Fifth unpinned entry is disabled at the four-pin limit");
            click(fifthPin);
            check(MenuService.pinnedIds.length === 4 && !MenuService.isPinned("control-center"), "Fifth pin is a no-op");
            check(MenuService.randomizedIds === randomizedAtOpen, "Pin writes retain order until the menu closes");
            setQuery(menu, "wallpapers");
            phase = 12;
        } else if (phase === 12) {
            check(menu.entries.length === 1 && menu.entries[0].id === "wallpapers", "Pinned entry can be found for unpinning");
            click(pinButton(menu, "wallpapers"));
            check(MenuService.pinnedIds.length === 3 && !MenuService.isPinned("wallpapers"), "Unpin removes the selected entry");
            setQuery(menu, "control-center");
            phase = 13;
        } else if (phase === 13) {
            check(menu.entries.length === 1, "Fifth entry is filtered after unpinning");
            check(pinButton(menu, "control-center").enabled, "Unpinning enables another pin");
            click(pinButton(menu, "control-center"));
            check(MenuService.pinnedIds.length === 4 && MenuService.isPinned("control-center"), "A new pin fills the available slot");
            phase = 14;
        } else if (phase === 14) {
            if (ThemeService.settings.menuPinnedEntries.length !== 4 || !MenuService.isPinned("control-center")) return;
            check(JSON.stringify(ThemeService.settings.menuPinnedEntries) === JSON.stringify(["themes", "settings", "shell-mode", "control-center"]), "Final pin order is persisted");
            check(MenuService.pendingPinnedIds === null, "Final optimistic pin state reconciles");
            testRoutes();
        } else if (phase === 80) {
            check(menu.entries.length === 1 && menu.entries[0].id === pendingId, "Route search result is present: " + pendingId);
            finishRoute();
        } else if (phase === 81) {
            const sectionIndex = inlineSections.findIndex(section => pendingId === "settings-" + section);
            if (sectionIndex >= 0)
                check(IslandState.mode === IslandState.settingsSectionMode && IslandState.settingsSection === inlineSections[sectionIndex], "Inline settings route opens " + pendingId);
            else {
                const expectedMode = controllerRoutes.find(route => route[0] === pendingId)[1];
                check(IslandState.mode === expectedMode, "Controller route opens " + pendingId);
            }
            IslandController.reset();
            routeIndex++;
            phase = 14;
        } else if (phase === 90) {
            openMenu();
            check(JSON.stringify(MenuService.pinnedIds) === JSON.stringify(["themes", "settings", "shell-mode", "control-center"]), "Saved pins survive reopening Menu");
            check(MenuService.randomizedIds !== randomizedAtOpen, "A new open gets a new order after route transitions");
            check(MenuService.togglePin("themes"), "Rapid unpin of Themes is accepted");
            check(MenuService.togglePin("themes"), "Rapid re-pin of Themes is accepted");
            check(MenuService.togglePin("settings"), "Rapid unpin of Settings is accepted");
            check(MenuService.togglePin("settings"), "Rapid re-pin of Settings is accepted");
            check(JSON.stringify(MenuService.pinnedIds) === JSON.stringify(["shell-mode", "control-center", "themes", "settings"]), "Rapid toggles expose the latest pin order immediately");
            check(IslandState.mode === IslandState.navigationMode, "Rapid pin writes keep Menu open");
            phase = 91;
        } else if (phase === 91) {
            const expected = ["shell-mode", "control-center", "themes", "settings"];
            if (JSON.stringify(ThemeService.settings.menuPinnedEntries) !== JSON.stringify(expected)
                || MenuService.pendingPinnedIds !== null) return;
            check(!ThemeService.busy && ThemeService.pending.length === 0, "Rapid writes fully drain before optimistic pins reconcile");
            check(JSON.stringify(MenuService.pinnedIds) === JSON.stringify(expected), "Latest rapid pin order remains after reconciliation");
            console.log("PASS: menu layout, search, shared views, persistent pins, cap and refill, rapid queued toggles, keyboard routing, settings routes, and mode transitions");
            Qt.quit();
        }
    }
    TestEvent { id: input }
    FloatingWindow {
        visible: true
        implicitWidth: 980
        implicitHeight: 640
        NavigationView { id: menu; width: 460; height: implicitHeight }
        NavigationView { id: secondMenu; x: 500; width: 460; height: implicitHeight }
    }
    Timer {
        interval: 100; running: true; repeat: true
        onTriggered: {
            try { root.tick(); }
            catch (error) { console.error("FAIL: " + error); Qt.quit(); }
        }
    }
}
