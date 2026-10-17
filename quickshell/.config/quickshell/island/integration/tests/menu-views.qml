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
    property int scrollSettleTicks: 0
    property int pinIndex: 0
    property var reorderOrderBefore: null
    property real reorderContentYBefore: 0
    property var randomizedAtOpen: null
    property string pendingId: ""
    property var pinChoices: ["themes", "wallpapers", "settings", "ai-usage"]
    property var nextPins: [
        ["themes"],
        ["themes", "wallpapers"],
        ["themes", "wallpapers", "settings"],
        ["themes", "wallpapers", "settings", "ai-usage"]
    ]
    property var inlineSections: ["launcher", "menu", "appearance", "desktop", "clock", "lock", "osd", "workspaces", "dynamicPalette", "notifications", "interaction", "wallpaperAnimation", "media", "screenRecording"]
    property var controllerRoutes: [
        ["session", IslandState.powerMenuMode],
        ["control-center", IslandState.controlCenterMode],
        ["audio-devices", IslandState.audioDevicesMode],
        ["wifi", IslandState.wifiMode],
        ["bluetooth", IslandState.bluetoothMode],
        ["power-profile", IslandState.powerProfileMode],
        ["proton-vpn", IslandState.protonVpnMode],
        ["clipboard", IslandState.clipboardMode],
        ["chromack", IslandState.chromackMode],
        ["browse-wallpapers", IslandState.wallhavenMode],
        ["shell-mode", IslandState.shellSwitcherMode],
        ["layout", IslandState.layoutSwitcherMode],
        ["ai-usage", IslandState.aiUsageMode],
        ["system", IslandState.systemMode]
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
    function dragCard(view, id, targetId) {
        const source = card(view, id);
        const target = card(view, targetId);
        const grid = named(view, "menu-grid");
        check(source && target, "Drag source and target cards exist");
        input.mousePress(source, source.width / 2, source.height / 2, Qt.LeftButton, Qt.NoModifier, 0);
        const from = source.mapToItem(grid, source.width / 2, source.height / 2);
        const to = target.mapToItem(grid, target.width / 2, target.height / 2);
        input.mouseMove(grid, from.x + (to.x - from.x) / 2, from.y + (to.y - from.y) / 2, 0, Qt.LeftButton, Qt.NoModifier);
        input.mouseMove(grid, to.x, to.y, 0, Qt.LeftButton, Qt.NoModifier);
        check(source.reordering && view.reorderTarget !== view.reorderFrom, "Held pointer drag activates reordering and reaches a drop target");
        const contentY = grid.contentY;
        input.mouseWheel(grid, grid.width / 2, grid.height / 2, Qt.NoButton, Qt.NoModifier, 0, -120, 0);
        check(grid.contentY === contentY && !grid.scrollAnimationRunning, "Wheel input does not scroll during a reorder");
        input.mouseRelease(grid, to.x, to.y, Qt.LeftButton, Qt.NoModifier, 0);
    }
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
    function testSlashToggle(view) {
        const search = named(view, "menu-search");
        const grid = named(view, "menu-grid");
        grid.forceActiveFocus();
        input.keyClick(Qt.Key_Slash, Qt.NoModifier, 0);
        check(view.searchVisible && search.activeFocus, "Slash opens search and focuses the field");
        input.keyClick(Qt.Key_Slash, Qt.NoModifier, 0);
        check(!view.searchVisible && search.text === "", "Slash in the focused field closes and clears search without typing");
        grid.forceActiveFocus();
        input.keyClick(Qt.Key_Slash, Qt.NoModifier, 0);
        check(view.searchVisible, "Slash opens search from grid focus");
        grid.forceActiveFocus();
        input.keyClick(Qt.Key_Slash, Qt.NoModifier, 0);
        check(!view.searchVisible && search.text === "", "Slash from grid focus closes search");
        input.keyClick(Qt.Key_Slash, Qt.ControlModifier, 0);
        check(!view.searchVisible && search.text === "", "Modified slash does not toggle search");
    }
    function queryFor(id) {
        if (id === "system") return "system stats";
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
            check(menu.entries.length > MenuService.cardLimit && menu.entries.every(entry => entry.route.type !== "settings"), "Closed menu lists more than its visible cards for scrolling, without settings pages");
            phase = 1;
        } else if (phase === 1) {
            check(menu.implicitHeight === 392 && menu.height === 392, "Menu is 392 px tall when search is closed: " + menu.height);
            const grid = named(menu, "menu-grid");
            check(grid.height === 276, "Menu card grid keeps its height");
            check(!grid.interactive && grid.contentHeight + grid.bottomMargin > grid.height && grid.contentY === 0, "The overflowing closed grid disables pointer flicking");
            const firstCard = card(menu, menu.entries[0].id);
            const secondColumnCard = card(menu, menu.entries[1].id);
            check(firstCard && firstCard.height === 132, "Navigation cards are 132 px tall");
            check(firstCard.width === 200 && secondColumnCard.width === 200, "Menu cards use two 200 px columns");
            check(secondColumnCard.x - firstCard.x === 212, "Menu cards have a 12 px column gap");
            check(firstCard.background.radius === 26, "Navigation cards keep 26 px corners");
            check(JSON.stringify(secondMenu.entries.map(entry => entry.id)) === JSON.stringify(menu.entries.map(entry => entry.id)), "Both views display the same randomized choices");
            randomizedAtOpen = MenuService.randomizedIds;
            grid.forceActiveFocus();
            check(grid.currentIndex === 0, "Closed menu starts keyboard navigation at the first card");
            input.keyClick(Qt.Key_Down, Qt.NoModifier, 0);
            check(grid.currentIndex >= 2 && grid.contentY === 0, "Down to the last visible row keeps the grid at the top");
            check(input.mouseWheel(grid, grid.width / 2, grid.height / 2, Qt.NoButton, Qt.NoModifier, 0, -120, 0), "Deliver wheel input over the closed grid");
            scrollSettleTicks = 0;
            phase = 100;
        } else if (phase === 100) {
            if (++scrollSettleTicks < 4) return;
            check(named(menu, "menu-grid").contentY === 144, "One wheel step scrolls the closed grid by a row: " + named(menu, "menu-grid").contentY);
            click(named(menu, "panel-title-action"));
            check(menu.implicitHeight === 452, "Opening search reports the final menu height immediately");
            check(named(menu, "menu-grid").y === 0, "Cards slide down with the search reveal instead of jumping");
            phase = 101;
        } else if (phase === 101) {
            const grid = named(menu, "menu-grid");
            check(menu.searchVisible && menu.entries.length === MenuEntries.browsableIds().length, "Search opens with every non-settings entry");
            check(menu.entries.every(entry => entry.route.type !== "settings"), "Blank search hides settings pages");
            check(input.mouseWheel(grid, grid.width / 2, grid.height / 2, Qt.NoButton, Qt.NoModifier, 0, -120, 0), "Deliver wheel input over all search results");
            scrollSettleTicks = 0;
            phase = 102;
        } else if (phase === 102) {
            if (++scrollSettleTicks < 4) return;
            check(named(menu, "menu-grid").contentY > 0, "All search results remain scrollable");
            click(named(menu, "panel-title-action"));
            scrollSettleTicks = 0;
            phase = 103;
        } else if (phase === 103) {
            if (++scrollSettleTicks < 4) return;
            const grid = named(menu, "menu-grid");
            check(!menu.searchVisible && grid.contentY === 0, "Closing scrolled search resets the grid to the top");
            click(named(menu, "panel-title-action"));
            named(menu, "menu-search").text = "session";
            scrollSettleTicks = 0;
            phase = 104;
        } else if (phase === 104) {
            if (++scrollSettleTicks < 2) return;
            const grid = named(menu, "menu-grid");
            check(menu.entries.length <= 4 && grid.contentY === 0, "Four or fewer filtered entries stay fixed at the top");
            named(menu, "menu-search").clear();
            scrollSettleTicks = 0;
            phase = 2;
        } else if (phase === 2) {
            if (++scrollSettleTicks < 4) return;
            check(menu.searchVisible && named(menu, "menu-search").activeFocus, "Search action focuses the search field");
            check(menu.height === 452, "Open search adds 60 px to menu height: " + menu.height);
            check(named(menu, "menu-grid").y === 60 && named(menu, "menu-search").opacity === 1, "Search reveal settles above the cards");
            check(menu.entries.length === MenuEntries.browsableIds().length, "Empty query shows every non-settings entry");
            named(menu, "menu-search").text = "session";
            phase = 3;
        } else if (phase === 3) {
            check(menu.entries.length === 1 && menu.entries[0].id === "session", "Session search result is correct");
            check(MenuService.randomizedIds === randomizedAtOpen, "Search does not change the open menu order");
            const search = named(menu, "menu-search");
            search.text = "provider credits";
            check(menu.entries.length === 1 && menu.entries[0].id === "ai-usage", "Provider keywords find AI Usage");
            search.text = "anthropic";
            check(menu.entries.length === 1 && menu.entries[0].id === "ai-usage", "Configured provider names find AI Usage");
            search.text = "session";
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
            testSlashToggle(menu);
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
            check(JSON.stringify(ThemeService.settings.menuPinnedEntries) === JSON.stringify(["themes", "settings", "ai-usage", "control-center"]), "Final pin order is persisted");
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
            if (pendingId === "system") {
                check(IslandState.systemReturnMode === IslandState.navigationMode, "System opened from Menu remembers Menu");
                IslandController.backFromSystem();
                check(IslandState.mode === IslandState.navigationMode, "System back returns to Menu");
            }
            IslandController.reset();
            routeIndex++;
            phase = 14;
        } else if (phase === 90) {
            openMenu();
            // Route tests can leave search open; the pinned checks below need the unsearched grid.
            if (menu.searchVisible) menu.toggleSearch();
            check(JSON.stringify(MenuService.pinnedIds) === JSON.stringify(["themes", "settings", "ai-usage", "control-center"]), "Saved pins survive reopening Menu");
            check(MenuService.randomizedIds !== randomizedAtOpen, "A new open gets a new order after route transitions");
            scrollSettleTicks = 0;
            phase = 89;
        } else if (phase === 89) {
            if (++scrollSettleTicks < 3) return;
            const pinned = ["themes", "settings", "ai-usage", "control-center"];
            check(pinned.every(id => card(menu, id).reorderable), "Pinned cards are reorderable outside search");
            check(!card(menu, "themes").dropTarget && !card(menu, "themes").reordering, "Pinned cards start without a drop target");
            const grid = named(menu, "menu-grid");
            grid.forceActiveFocus();
            grid.currentIndex = 0;
            check(card(menu, menu.entries[0].id).selected, "First pinned card is selected before drag");
            reorderOrderBefore = MenuService.pinnedIds.slice();
            reorderContentYBefore = grid.contentY;
            dragCard(menu, menu.entries[0].id, menu.entries[2].id);
            phase = 890;
        } else if (phase === 890) {
            if (++scrollSettleTicks < 3) return;
            check(JSON.stringify(MenuService.pinnedIds) !== JSON.stringify(reorderOrderBefore), "Dragging the selected pinned card changes pin order");
            check(named(menu, "menu-grid").contentY === reorderContentYBefore, "Dragging the selected pinned card does not scroll the grid");
            const grid = named(menu, "menu-grid");
            grid.currentIndex = 0;
            const unselectedId = menu.entries[1].id;
            check(!card(menu, unselectedId).selected, "Second pinned card is unselected before drag");
            reorderOrderBefore = MenuService.pinnedIds.slice();
            reorderContentYBefore = grid.contentY;
            dragCard(menu, unselectedId, menu.entries[3].id);
            scrollSettleTicks = 0;
            phase = 891;
        } else if (phase === 891) {
            if (++scrollSettleTicks < 3) return;
            check(JSON.stringify(MenuService.pinnedIds) !== JSON.stringify(reorderOrderBefore), "Dragging an unselected pinned card changes pin order");
            check(named(menu, "menu-grid").contentY === reorderContentYBefore, "Dragging the unselected pinned card does not scroll the grid");
            MenuService.movePin("ai-usage", 0);
            MenuService.movePin("control-center", 1);
            MenuService.movePin("themes", 2);
            MenuService.movePin("settings", 3);
            scrollSettleTicks = 0;
            phase = 892;
        } else if (phase === 892) {
            const expected = ["ai-usage", "control-center", "themes", "settings"];
            if (JSON.stringify(ThemeService.settings.menuPinnedEntries) !== JSON.stringify(expected)
                || MenuService.pendingPinnedIds !== null || ++scrollSettleTicks < 3) return;
            startSearch(menu).text = queryFor("themes");
            scrollSettleTicks = 0;
            phase = 893;
        } else if (phase === 893) {
            if (++scrollSettleTicks < 3) return;
            check(card(menu, "themes") && !card(menu, "themes").reorderable, "Pinned cards are not reorderable while searching");
            menu.toggleSearch();
            scrollSettleTicks = 0;
            phase = 894;
        } else if (phase === 894) {
            if (++scrollSettleTicks < 3) return;
            check(card(menu, "themes").reorderable, "Pinned cards become reorderable again after search closes");
            check(MenuService.togglePin("themes"), "Rapid unpin of Themes is accepted");
            check(MenuService.togglePin("themes"), "Rapid re-pin of Themes is accepted");
            check(MenuService.togglePin("settings"), "Rapid unpin of Settings is accepted");
            check(MenuService.togglePin("settings"), "Rapid re-pin of Settings is accepted");
            check(JSON.stringify(MenuService.pinnedIds) === JSON.stringify(["ai-usage", "control-center", "themes", "settings"]), "Rapid toggles expose the latest pin order immediately");
            check(IslandState.mode === IslandState.navigationMode, "Rapid pin writes keep Menu open");
            phase = 91;
        } else if (phase === 91) {
            const expected = ["ai-usage", "control-center", "themes", "settings"];
            if (JSON.stringify(ThemeService.settings.menuPinnedEntries) !== JSON.stringify(expected)
                || MenuService.pendingPinnedIds !== null) return;
            check(!ThemeService.busy && ThemeService.pending.length === 0, "Rapid writes fully drain before optimistic pins reconcile");
            check(JSON.stringify(MenuService.pinnedIds) === JSON.stringify(expected), "Latest rapid pin order remains after reconciliation");
            secondMenu.visible = false;
            if (menu.searchVisible) menu.toggleSearch();
            ThemeService.setSetting("menuRows", 3);
            ThemeService.setSetting("menuColumns", 4);
            scrollSettleTicks = 0;
            phase = 92;
        } else if (phase === 92) {
            if (ThemeService.settings.menuRows !== 3 || ThemeService.settings.menuColumns !== 4) return;
            if (++scrollSettleTicks < 4) return;
            const grid = named(menu, "menu-grid");
            check(MenuService.cardLimit === 12 && menu.entries.length > 12, "A 3x4 grid shows twelve cards and scrolls to the rest");
            check(menu.implicitWidth === 884 && menu.width === 884, "Four columns widen the menu: " + menu.width);
            
            const first = card(menu, menu.entries[0].id);
            const fourth = card(menu, menu.entries[3].id);
            const fifth = card(menu, menu.entries[4].id);
            check(grid.height === 420 && grid.contentHeight + grid.bottomMargin > grid.height, "Three visible rows scroll to the remaining entries");
            check(first.width === 200 && fourth.x - first.x === 636 && fifth.y - first.y === 144, "Larger grids keep 200 px cards and 12 px gaps");
            check(pinButton(menu, menu.entries[4].id).enabled, "A larger grid allows more pins");
            click(named(menu, "panel-title-action"));
            scrollSettleTicks = 0;
            phase = 93;
        } else if (phase === 93) {
            if (++scrollSettleTicks < 4) return;
            const grid = named(menu, "menu-grid");
            check(menu.searchVisible && !grid.interactive && grid.contentY === 0, "Search results disable pointer flicking in the larger grid");
            check(input.mouseWheel(grid, grid.width / 2, grid.height / 2, Qt.NoButton, Qt.NoModifier, 0, -120, 0), "Deliver wheel input over the larger grid");
            scrollSettleTicks = 0;
            phase = 94;
        } else if (phase === 94) {
            if (++scrollSettleTicks < 5) return;
            check(named(menu, "menu-grid").contentY === 144, "One wheel step scrolls one row of four results: " + named(menu, "menu-grid").contentY);
            named(menu, "menu-search").text = "settings";
            phase = 945;
        } else if (phase === 945) {
            const settingsEntries = menu.entries.filter(entry => entry.route.type === "settings");
            check(settingsEntries.length === MenuEntries.settingsSections.length, "Search lists every settings page");
            check(settingsEntries.every(entry => entry.title.startsWith("Settings > ")), "Settings pages are labelled Settings > <entry> in search");
            check(menu.entries.filter(entry => entry.route.type !== "settings").every(entry => !entry.title.startsWith("Settings >")), "Other submenus are not labelled as settings");
            named(menu, "menu-search").text = "settings > clock";
            phase = 95;
        } else if (phase === 95) {
            check(menu.entries.length > 0 && menu.entries.length < 5 && menu.entries.some(entry => entry.id === "settings-clock" && entry.title === "Settings > Clock"), "Searching the full label finds the page: " + menu.entries.map(entry => entry.id));
            menu.visible = false;
            settingsPanel.visible = true;
            settingsPanel.forceActiveFocus();
            check(!settingsPanel.searchVisible && !named(settingsPanel, "settings-search").visible, "Settings search starts hidden");
            check(named(settingsPanel, "settings-entry-clock") && named(settingsPanel, "settings-entry-lock"), "Settings lists every page when not searching");
            input.keyClick(Qt.Key_Slash, Qt.ControlModifier, 0);
            check(!settingsPanel.searchVisible, "Modified slash does not open settings search");
            input.keyClick(Qt.Key_Slash, Qt.NoModifier, 0);
            check(settingsPanel.searchVisible && named(settingsPanel, "settings-search").activeFocus, "Slash opens settings search and focuses the field");
            check(settingsPanel.implicitHeight === 635, "Settings search keeps the panel at full height: " + settingsPanel.implicitHeight);
            input.keyClick(Qt.Key_Slash, Qt.NoModifier, 0);
            check(!settingsPanel.searchVisible && settingsPanel.searchText === "", "Slash in the field closes and clears settings search");
            click(named(settingsPanel, "panel-title-action"));
            check(settingsPanel.searchVisible && named(settingsPanel, "settings-search").activeFocus, "The header search button reveals the field");
            named(settingsPanel, "settings-search").text = "lockscreen";
            phase = 96;
        } else if (phase === 96) {
            check(settingsPanel.sections.length === 1 && settingsPanel.sections[0].key === "lock", "Settings search filters pages by keyword");
            check(named(settingsPanel, "settings-entry-lock") && !named(settingsPanel, "settings-entry-clock"), "Only matching pages stay listed");
            input.keyClick(Qt.Key_Down, Qt.NoModifier, 0);
            check(named(settingsPanel, "settings-entry-lock").activeFocus, "Down moves from the field to the first page");
            input.keyClick(Qt.Key_Up, Qt.NoModifier, 0);
            check(named(settingsPanel, "settings-search").activeFocus, "Up from the first page returns to the field");
            named(settingsPanel, "settings-search").text = "zzzz";
            phase = 97;
        } else if (phase === 97) {
            check(settingsPanel.sections.length === 0, "Unknown terms match no pages");
            named(settingsPanel, "settings-search").text = "lockscreen";
            phase = 98;
        } else if (phase === 98) {
            input.keyClick(Qt.Key_Enter, Qt.NoModifier, 0);
            check(IslandState.mode === IslandState.settingsSectionMode && IslandState.settingsSection === "lock", "Enter opens the first matching page");
            IslandController.reset();
            phase = 981;
        } else if (phase === 981) {
            named(settingsPanel, "settings-search").forceActiveFocus();
            input.keyClick(Qt.Key_Escape, Qt.NoModifier, 0);
            check(!settingsPanel.searchVisible && settingsPanel.searchText === "", "Escape hides and clears settings search first: " + settingsPanel.searchVisible + " " + named(settingsPanel, "settings-search").activeFocus + " " + IslandState.mode);
            phase = 99;
        } else if (phase === 99) {
            settingsPanel.forceActiveFocus();
            input.keyClick(Qt.Key_F, Qt.ControlModifier, 0);
            check(settingsPanel.searchVisible && named(settingsPanel, "settings-search").activeFocus, "Ctrl+F reveals settings search");
            input.keyClick(Qt.Key_Escape, Qt.NoModifier, 0);
            IslandController.openSettings();
            settingsPanel.forceActiveFocus();
            input.keyClick(Qt.Key_Escape, Qt.NoModifier, 0);
            check(IslandState.mode === IslandState.defaultMode, "Second Escape closes Settings");
            console.log("PASS: menu layout, search, shared views, persistent pins, cap and refill, rapid queued toggles, keyboard routing, settings routes, settings labels and search, mode transitions, and configurable grid size");
            Qt.quit();
        }
    }
    TestEvent { id: input }
    FloatingWindow {
        visible: true
        implicitWidth: 980
        implicitHeight: 760
        NavigationView { id: menu; width: implicitWidth; height: implicitHeight }
        NavigationView { id: secondMenu; x: 500; width: 460; height: implicitHeight }
        SettingsView { id: settingsPanel; visible: false; width: implicitWidth; height: implicitHeight }
    }
    Timer {
        interval: 100; running: true; repeat: true
        onTriggered: {
            try { root.tick(); }
            catch (error) { console.error("FAIL: " + error); Qt.quit(); }
        }
    }
}
