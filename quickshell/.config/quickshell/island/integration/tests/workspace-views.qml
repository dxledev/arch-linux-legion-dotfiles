import QtQuick
import Quickshell
import "../../components"
import "../../views"
import "../../core"
import "../../services"
import "../../styles"
import "../../services/MonitorSelection.js" as MonitorSelection

ShellRoot {
    id: root
    property int phase: 0
    property var previousDot
    property var clock
    property var status
    property var initialStatus
    property int elapsed: 0

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }
    function expectIds(expected) {
        check(JSON.stringify(dots.entries.map(entry => entry.id)) === JSON.stringify(expected), "Workspace IDs: " + JSON.stringify(dots.entries));
    }
    function child(item, name) {
        if (item.objectName === name) return item;
        for (const candidate of item.children) {
            const found = child(candidate, name);
            if (found) return found;
        }
        return null;
    }
    function next() {
        elapsed = 0;
        phase++;
    }
    function tick() {
        elapsed += 40;
        switch (phase) {
        case 0:
            if (!ThemeService.ready) return;
            const screens = [{name: "HDMI-A-1"}, {name: "DP-1"}];
            check(MonitorSelection.screensForSetting(screens, "all").length === 2, "Island on all monitors");
            check(MonitorSelection.screensForSetting(screens, "automatic").length === 2, "Migrate automatic to all");
            check(MonitorSelection.screensForSetting(screens, "DP-1")[0] === screens[1], "Select one monitor");
            check(MonitorSelection.screensForSetting(screens, "missing")[0] === screens[0], "Disconnected monitor fallback");
            check(MonitorSelection.screensForSetting([], "all").length === 0, "No connected monitors");
            const fixtures = [
                {id: 1, monitor: {name: "HDMI-A-1"}},
                {id: 10, monitor: {name: "DP-1"}}
            ];
            const pins = [
                {workspaceString: "1", monitor: "HDMI-A-1", persistent: true},
                {workspaceString: "2", monitor: "HDMI-A-1", persistent: false},
                {workspaceString: "10", monitor: "DP-1", persistent: true},
                {workspaceString: "11", monitor: "DP-1", persistent: true},
                {workspaceString: "12", monitor: "DP-1", persistent: true, enabled: false}
            ];
            check(WorkspaceService.workspacesForMonitor(fixtures, "HDMI-A-1", false).length === 1, "Filter current monitor");
            check(WorkspaceService.workspacesForMonitor(fixtures, "HDMI-A-1", true).length === 2, "Include all monitors");
            const secondary = {name: "DP-1", description: "Secondary display"};
            const primary = {name: "HDMI-A-1", description: "Primary display"};
            check(JSON.stringify(WorkspaceService.persistentForMonitor(pins, secondary, false)) === "[10,11]", "Respect connector persistent rules");
            check(JSON.stringify(WorkspaceService.persistentForMonitor(pins, secondary, true)) === "[1,10,11]", "Include all persistent rules");
            const describedPins = [
                ...Array.from({length: 5}, (_, index) => ({workspaceString: String(index + 1), monitor: "desc:Primary display", persistent: true})),
                {workspaceString: "10", monitor: "desc:Secondary display", persistent: true},
                {workspaceString: "11", monitor: "desc:Secondary display", persistent: true},
                {workspaceString: "12", monitor: "desc:Disconnected display", persistent: true},
                {workspaceString: "6", monitor: "desc:Primary display", persistent: false},
                {workspaceString: "7", monitor: "desc:Primary display", persistent: true, enabled: false},
                {workspaceString: "special:scratchpad", monitor: "desc:Primary display", persistent: true}
            ];
            check(JSON.stringify(WorkspaceService.persistentForMonitor(describedPins, primary, false)) === "[1,2,3,4,5]", "Shared backend primary persistent rules");
            check(JSON.stringify(WorkspaceService.persistentForMonitor(describedPins, secondary, false)) === "[10,11]", "Keep other monitor persistent rules separate");
            check(WorkspaceService.persistentForMonitor(describedPins, null, false).length === 0, "Missing monitor cannot match description rules");
            check(JSON.stringify(WorkspaceService.persistentForMonitor(describedPins, primary, true)) === "[1,2,3,4,5,10,11,12]", "All monitors includes described persistent rules");
            expectIds([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 14]);
            check(child(dots, "workspace-dot-3").width === 18, "Active dot width");
            check(child(dots, "workspace-dot-3").color.toString() === Theme.accent.toString(), "Active dot color");
            check(child(dots, "workspace-dot-1").color.toString() === Theme.textSecondary.toString(), "Occupied dot color");
            check(child(dots, "workspace-dot-2").color.toString() === Theme.surface.toString(), "Empty dot color");
            dots.dotSize = 12;
            check(child(dots, "workspace-dot-2").height === 12 && child(dots, "workspace-dot-3").width === 22, "Resize dots and active pill");
            dots.dotSize = 100;
            check(child(dots, "workspace-dot-2").height === IslandGeometry.compactHeight - 2, "Cap dot height below Island height");
            check(child(dots, "workspace-dot-2").radius === dots.diameter / 2, "Keep resized dots circular");
            dots.dotSize = 8;
            dots.persistent = false;
            expectIds([1, 3, 4, 14]);
            dots.activeWorkspace = 7;
            expectIds([1, 4, 7, 14]);
            dots.persistent = true;
            dots.persistentCount = 5;
            expectIds([1, 2, 3, 4, 5, 7, 14]);
            dots.persistent = false;
            dots.activeWorkspace = 1;
            dots.workspaces = [workspace];
            expectIds([1]);
            workspace.lastIpcObject = {windows: 1};
            expectIds([1, 2]);
            workspace.lastIpcObject = {windows: 0};
            expectIds([1]);
            dots.persistent = true;
            dots.activeWorkspace = 3;
            next();
            break;
        case 1:
            previousDot = child(dots, "workspace-dot-3");
            dots.animationDuration = 160;
            dots.activeWorkspace = 4;
            next();
            break;
        case 2:
            check(child(dots, "workspace-dot-3") === previousDot, "Keep delegate across workspace switches");
            check(previousDot.width > 8 && previousDot.width < 18, "Animate active dot width");
            next();
            break;
        case 3:
            if (elapsed < 200) return;
            check(previousDot.width === 8 && child(dots, "workspace-dot-4").width === 18, "Finish dot animation");
            dots.persistentIds = [10, 11];
            dots.activeWorkspace = 11;
            expectIds([10, 11]);
            ThemeService.settings = {workspaceStyle: "default", workspaceAnimationDuration: 160};
            StatusManager.mode = "workspace";
            StatusManager.visible = false;
            clock = child(compact, "compact-clock");
            status = child(compact, "compact-status");
            initialStatus = status;
            StatusManager.show({mode: "workspace", icon: "", title: "2", value: 2});
            next();
            break;
        case 4:
            check(clock.opacity > 0 && clock.opacity < 1 && status.opacity > 0 && status.opacity < 1, "Animate into workspace view");
            StatusManager.visible = false;
            next();
            break;
        case 5:
            if (elapsed < 200) return;
            check(clock.opacity === 1 && status.opacity === 0, "Return after interrupted entrance");
            StatusManager.visible = true;
            next();
            break;
        case 6:
            if (elapsed < 200) return;
            check(clock.opacity === 0 && status.opacity === 1, "Finish entrance");
            StatusManager.visible = false;
            next();
            break;
        case 7:
            check(clock.opacity > 0 && clock.opacity < 1 && status.opacity > 0 && status.opacity < 1, "Animate back to clock");
            next();
            break;
        case 8:
            if (elapsed < 200) return;
            check(clock.opacity === 1 && status.opacity === 0 && status === initialStatus, "Finish return and retain view");
            console.log("PASS: workspace states, persistence, live occupancy updates, delegate reuse, and both transition directions");
            Qt.quit();
        }
    }

    QtObject { id: workspace; property int id: 2; property var lastIpcObject: ({windows: 0}) }
    FloatingWindow {
        visible: true
        implicitWidth: 400
        implicitHeight: 100
        WorkspaceDots {
            id: dots
            activeWorkspace: 3
            animationDuration: 0
            workspaces: [
                {id: 1, lastIpcObject: {windows: 2}},
                {id: 4, lastIpcObject: {windows: 1}},
                {id: 14, lastIpcObject: {windows: 1}},
                {id: 20, lastIpcObject: {windows: 0}},
                {id: -99, lastIpcObject: {windows: 1}}
            ]
        }
        CompactView { id: compact; y: 40 }
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
