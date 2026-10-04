import QtQuick
import QtTest
import Quickshell
import "../../views"
import "../../services"
import "../../core"
import "../../island"
import "../../services/LauncherSearch.js" as Search

ShellRoot {
    id: root
    property int phase: 0
    function check(condition, message) { if (!condition) throw new Error(message); }
    function named(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const found = named(child, name);
            if (found) return found;
        }
        return null;
    }
    function checkSearch() {
        const apps = [
            {id: "a", name: "Calculator", description: "Math", keywords: []},
            {id: "b", name: "Calendar", description: "Dates", keywords: []},
            {id: "c", name: "LocalSend", description: "Transfer", keywords: ["sharing"]}
        ];
        check(Search.results(apps, "clc", {launcherMatching: "Fuzzy"}, {}).length === 1, "Fuzzy subsequence matching");
        check(Search.results(apps, "clc", {launcherMatching: "Contains"}, {}).length === 0, "Contains excludes fuzzy results");
        check(Search.results(apps, "calendar", {}, {})[0].id === "b", "Exact name ranks first");
        check(Search.results(apps, "sharing", {launcherSearchDescriptions: true}, {})[0].id === "c", "Keyword matching");
        check(Search.results(apps, "sharing", {}, {}).length === 0, "Description search is optional");
        check(Search.results(apps, "", {}, {})[0].id === "a", "Default preserves configured order");
        const usage = {b: {count: 4, lastUsed: 10}, c: {count: 1, lastUsed: 20}};
        check(Search.results(apps, "", {launcherDefaultOrder: "Most used"}, usage)[0].id === "b", "Frequency ordering");
        check(Search.results(apps, "", {launcherDefaultOrder: "Recently used"}, usage)[0].id === "c", "Recency ordering");
    }
    function tick() {
        if (!ThemeService.ready || ThemeService.busy || LauncherService.loading) return;
        if (phase === 0) {
            checkSearch();
            check(LauncherService.applications.length > 0, "All installed desktop apps loaded");
            ThemeService.setSetting("launcherShowAllApps", false);
            phase++;
        } else if (phase === 1) {
            if (ThemeService.settings.launcherShowAllApps) return;
            check(LauncherService.applications.length === 3, "Configured list loaded with custom launchers");
            const custom = LauncherService.applications.find(app => app.launcher === "launch-obsidian");
            check(custom?.name === "Obsidian", "Custom app name preserved");
            check(LauncherService.launch(custom, true) === "launch-obsidian", "Dry run preserves custom launch command");
            check(!LauncherService.usage[custom.id], "Dry run does not record usage");
            check(LauncherService.launch(custom), "Custom launcher invokes configured helper");
            check(LauncherService.usage[custom.id].count === 1, "Successful dispatch records frequency");
            const search = named(launcher, "launcher-search");
            search.text = "obsidian";
            check(launcher.results.length === 1 && launcher.results[0].name === "Obsidian", "Search updates visible model");
            search.text = "";
            phase++;
        } else if (phase === 2) {
            const search = named(launcher, "launcher-search");
            search.forceActiveFocus();
            input.keyClick(Qt.Key_Down, Qt.NoModifier, 0);
            check(named(launcher, "launcher-results").currentIndex === 1, "Down navigates from search input");
            input.keyClick(Qt.Key_Up, Qt.NoModifier, 0);
            check(named(launcher, "launcher-results").currentIndex === 0, "Up navigates from search input");
            IslandController.toggleMode(IslandState.launcherMode, [], "DP-1");
            check(IslandState.modal && IslandState.panelMonitorName === "DP-1", "Launcher owns originating monitor");
            IslandController.toggleMode(IslandState.launcherMode, [], "DP-1");
            check(IslandState.mode === IslandState.defaultMode, "Shortcut toggles closed");
            IslandController.toggleSettingsSection("launcher", "DP-1");
            check(IslandState.settingsSection === "launcher" && IslandState.modal, "Dedicated settings route");
            ThemeService.setSetting("launcherMatching", "Contains");
            ThemeService.setSetting("launcherSearchOrder", "Most used");
            phase++;
        } else {
            if (ThemeService.settings.launcherMatching !== "Contains" || ThemeService.settings.launcherSearchOrder !== "Most used") return;
            check(named(settings, "setting-choice-Matching").currentText === "Contains", "Settings update persisted selection");
            console.log("PASS: launcher search, configured apps, keyboard selection, dry run, settings persistence, and monitor routing");
            Qt.quit();
        }
    }
    TestEvent { id: input }
    FloatingWindow {
        visible: true
        implicitWidth: 1200
        implicitHeight: 700
        LauncherSettingsView { id: settings; x: 600 }
        LauncherView { id: launcher }
    }
    Timer {
        interval: 100; running: true; repeat: true
        onTriggered: {
            try { root.tick(); }
            catch (error) { console.error("FAIL: " + error); Qt.quit(); }
        }
    }
}
