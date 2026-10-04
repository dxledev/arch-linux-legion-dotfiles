import QtQuick
import Quickshell
import "../../island"
import "../../core"
import "../../services"

ShellRoot {
    id: root
    property int activeMonitor: 0
    property int phase: 0
    property int elapsed: 0
    property var firstInteraction
    property var secondInteraction
    property var firstCompact
    property var secondCompact

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }

    function childWithProperty(item, name) {
        if (item[name] !== undefined) return item;
        for (const child of item.children) {
            const found = childWithProperty(child, name);
            if (found) return found;
        }
        return null;
    }

    function expectPanel(active, inactive, mode, height) {
        check(active.mode === mode, "Active monitor mode");
        check(childWithProperty(active, "currentView").implicitHeight === height, "Active monitor panel height");
        check(inactive.mode === IslandState.defaultMode, "Inactive monitor stays compact");
        check(childWithProperty(inactive, "currentView").implicitHeight === IslandGeometry.compactHeight, "Inactive monitor compact height");
        check(inactive.radius === 20, "Inactive monitor compact radius");
    }

    function childNamed(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const found = childNamed(child, name);
            if (found) return found;
        }
        return null;
    }

    function expectStatus(compact, showingStatus) {
        check(childNamed(compact, "compact-clock").opacity === (showingStatus ? 0 : 1), "Clock visibility");
        check(childNamed(compact, "compact-status").opacity === (showingStatus ? 1 : 0), "Workspace popup visibility");
    }

    function next() {
        phase++;
        elapsed = 0;
    }

    function tick() {
        elapsed += 40;
        switch (phase) {
        case 0:
            if (!ThemeService.ready) return;
            ThemeService.settings = {hoverDelay: 80, collapseDelay: 80, radius: 20, workspaceAnimationDuration: 160};
            StatusManager.visible = false;
            IslandController.reset();
            firstInteraction = childWithProperty(first, "handleHoverChanged");
            secondInteraction = childWithProperty(second, "handleHoverChanged");
            check(firstInteraction && secondInteraction, "Both monitor interactions exist");
            firstInteraction.handleHoverChanged(true);
            next();
            break;
        case 1:
            if (elapsed < 160) return;
            expectPanel(first, second, IslandState.expandedMode, 75);
            IslandController.openNavigation();
            check(first.mode === IslandState.navigationMode && second.mode === IslandState.defaultMode, "Navigation only on active monitor");
            IslandController.openWallpaperSelector();
            expectPanel(first, second, IslandState.wallpaperSelectorMode, 544);
            root.activeMonitor = 1;
            expectPanel(first, second, IslandState.wallpaperSelectorMode, 544);
            check(IslandState.panelMonitorName === "HDMI-A-1", "Panel stays on opening monitor after focus change");
            IslandController.openSettings();
            check(first.mode === IslandState.settingsMode && second.mode === IslandState.defaultMode, "Navigation preserves panel monitor");
            IslandController.reset();
            firstInteraction.handleHoverChanged(true);
            next();
            break;
        case 2:
            if (elapsed < 160) return;
            check(IslandState.mode === IslandState.defaultMode, "Inactive hover does not expand");
            secondInteraction.handleHoverChanged(true);
            root.activeMonitor = 0;
            next();
            break;
        case 3:
            if (elapsed < 160) return;
            check(IslandState.mode === IslandState.defaultMode, "Cancel previous monitor expansion timer");
            firstInteraction.handleHoverChanged(true);
            next();
            break;
        case 4:
            if (elapsed < 160) return;
            expectPanel(first, second, IslandState.expandedMode, 75);
            ThemeService.settings = Object.assign({}, ThemeService.settings, {collapseDelay: 400});
            firstInteraction.handleHoverChanged(false);
            next();
            break;
        case 5:
            if (elapsed < 240) return;
            expectPanel(first, second, IslandState.expandedMode, 75);
            root.activeMonitor = 1;
            next();
            break;
        case 6:
            if (elapsed < 240) return;
            check(IslandState.mode === IslandState.defaultMode, "Focus change preserves the original close deadline");
            check(IslandState.panelMonitorName === "", "Reset clears panel monitor");
            ThemeService.settings = Object.assign({}, ThemeService.settings, {collapseDelay: 80});
            secondInteraction.handleHoverChanged(true);
            next();
            break;
        case 7:
            if (elapsed < 160) return;
            expectPanel(second, first, IslandState.expandedMode, 75);
            check(IslandState.panelMonitorName === "DP-1", "Reopening selects newly active monitor");
            root.activeMonitor = 0;
            expectPanel(second, first, IslandState.expandedMode, 75);
            next();
            break;
        case 8:
            if (elapsed < 160) return;
            check(IslandState.mode === IslandState.defaultMode, "Losing focus while hovered starts the close delay");
            firstInteraction.handleHoverChanged(true);
            next();
            break;
        case 9:
            if (elapsed < 160) return;
            expectPanel(first, second, IslandState.expandedMode, 75);
            firstInteraction.handleHoverChanged(false);
            root.activeMonitor = 1;
            IslandController.openWallpaperSelector();
            next();
            break;
        case 10:
            if (elapsed < 160) return;
            expectPanel(first, second, IslandState.wallpaperSelectorMode, 544);
            IslandController.reset();
            root.activeMonitor = 0;
            firstInteraction.handleHoverChanged(true);
            next();
            break;
        case 11:
            if (elapsed < 160) return;
            IslandController.togglePin();
            root.activeMonitor = 1;
            next();
            break;
        case 12:
            if (elapsed < 160) return;
            expectPanel(first, second, IslandState.expandedMode, 75);
            check(IslandState.islandPinned, "Focus change preserves pinned panels");
            IslandController.reset();
            root.activeMonitor = 0;
            firstCompact = childWithProperty(first, "currentView").currentView;
            secondCompact = childWithProperty(second, "currentView").currentView;
            StatusManager.show({mode: "workspace", monitorName: "HDMI-A-1", icon: "", title: "2", value: 2});
            check(firstCompact.showingStatus && !secondCompact.showingStatus, "Workspace popup only on switching monitor");
            next();
            break;
        case 13:
            if (elapsed < 240) return;
            expectStatus(firstCompact, true);
            expectStatus(secondCompact, false);
            root.activeMonitor = 1;
            check(!firstCompact.showingStatus && !secondCompact.showingStatus, "Workspace popup does not follow focus to another monitor");
            StatusManager.show({mode: "workspace", monitorName: "DP-1", icon: "", title: "10", value: 10});
            check(secondCompact.showingStatus && !firstCompact.showingStatus, "Workspace popup switches with workspace event monitor");
            next();
            break;
        case 14:
            if (elapsed < 240) return;
            expectStatus(firstCompact, false);
            expectStatus(secondCompact, true);
            StatusManager.show({mode: "volume", icon: "", title: "50%", value: 50});
            check(firstCompact.showingStatus && secondCompact.showingStatus, "Other status visibility preserved");
            check(StatusManager.monitorName === "", "New status clears workspace monitor");
            console.log("PASS: active monitor panels, hover isolation, fixed panel monitor, close delay across focus changes, pinned and modal panels, and workspace popup routing");
            Qt.quit();
        }
    }

    FloatingWindow {
        visible: false
        implicitWidth: 1200
        implicitHeight: 600
        Island { id: first; monitorName: "HDMI-A-1"; monitorActive: root.activeMonitor === 0 }
        Island { id: second; x: 600; monitorName: "DP-1"; monitorActive: root.activeMonitor === 1 }
    }

    Timer {
        interval: 40
        running: true
        repeat: true
        onTriggered: {
            try { root.tick(); }
            catch (error) { console.error("FAIL: " + error); Qt.quit(); }
        }
    }
}
