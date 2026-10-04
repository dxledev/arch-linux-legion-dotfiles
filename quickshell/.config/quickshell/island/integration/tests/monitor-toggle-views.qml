import QtQuick
import Quickshell
import "../../island"
import "../../core"
import "../../services"
import "../../styles"

ShellRoot {
    id: root
    property int activeMonitor: 0
    property int scenario: 0
    property int phase: 0
    property int elapsed: 0
    readonly property var sourcePanel: scenario < 2 ? first : second
    readonly property var targetPanel: scenario < 2 ? second : first
    readonly property int targetMode: scenario % 2 === 0 ? IslandState.expandedMode : IslandState.notificationsMode
    property real sourceHeight: 0

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

    function next() {
        phase++;
        elapsed = 0;
    }

    function openSource() {
        activeMonitor = scenario < 2 ? 0 : 1;
        IslandController.toggleMode(IslandState.expandedMode, [], sourcePanel.monitorName);
    }

    function checkAnimation(panel) {
        check(Math.abs(panel.width - panel.implicitWidth) < 0.01, "Width follows its animation");
        check(Math.abs(panel.height - panel.implicitHeight) < 0.01, "Height follows its animation");
    }

    function tick() {
        elapsed += 40;
        switch (phase) {
        case 0:
            if (!ThemeService.ready) return;
            ThemeService.settings = {hoverDelay: 80, collapseDelay: 400};
            StatusManager.visible = false;
            IslandController.reset();
            openSource();
            next();
            break;
        case 1:
            if (elapsed < Theme.animationNormal + 100) return;
            sourceHeight = sourcePanel.height;
            check(sourceHeight > IslandGeometry.compactHeight, "Source expanded");
            childWithProperty(sourcePanel, "handleHoverChanged").handleHoverChanged(true);
            activeMonitor = activeMonitor === 0 ? 1 : 0;
            IslandController.toggleMode(targetMode, [], targetPanel.monitorName);
            check(sourcePanel.mode === IslandState.defaultMode, "Old monitor closes");
            check(targetPanel.mode === targetMode, "Requested panel opens on new monitor");
            check(IslandState.panelMonitorName === targetPanel.monitorName, "New monitor owns the panel");
            next();
            break;
        case 2:
            if (elapsed < 80) return;
            check(sourcePanel.height > IslandGeometry.compactHeight && sourcePanel.height < sourceHeight,
                "Old monitor closes gradually");
            check(targetPanel.height > IslandGeometry.compactHeight
                && targetPanel.height < childWithProperty(targetPanel, "currentView").implicitHeight,
                "New monitor expands gradually");
            checkAnimation(sourcePanel);
            checkAnimation(targetPanel);
            next();
            break;
        case 3:
            if (elapsed < 480) return;
            check(sourcePanel.height === IslandGeometry.compactHeight, "Old monitor finishes closing");
            check(targetPanel.height > IslandGeometry.compactHeight && targetPanel.mode === targetMode,
                "Old monitor close timer cannot reset the new panel");
            if (scenario === 0) {
                activeMonitor = 0;
                IslandController.toggleMode(targetMode, [], sourcePanel.monitorName);
                next();
            } else {
                IslandController.toggleMode(targetMode, [], targetPanel.monitorName);
                phase = 5;
                elapsed = 0;
            }
            break;
        case 4:
            if (elapsed < 80) return;
            check(sourcePanel.height > IslandGeometry.compactHeight, "Return transfer expands normally");
            check(targetPanel.height > IslandGeometry.compactHeight, "Return transfer closes normally");
            activeMonitor = 1;
            IslandController.toggleMode(targetMode, [], targetPanel.monitorName);
            next();
            break;
        case 5:
            if (elapsed < Theme.animationNormal + 100) return;
            if (scenario === 0) {
                check(sourcePanel.height === IslandGeometry.compactHeight && targetPanel.mode === targetMode,
                    "Rapid transfer settles on the requested monitor");
                IslandController.toggleMode(targetMode, [], targetPanel.monitorName);
                elapsed = 0;
                phase = 6;
            } else {
                phase = 6;
            }
            break;
        case 6:
            if (elapsed < Theme.animationNormal + 100) return;
            check(IslandState.mode === IslandState.defaultMode, "Second toggle closes on owning monitor");
            check(first.height === IslandGeometry.compactHeight && second.height === IslandGeometry.compactHeight,
                "Both monitors finish compact");
            scenario++;
            if (scenario === 4) {
                console.log("PASS: monitor panel transfers, normal animations, stale close timers, and rapid toggles");
                Qt.quit();
                return;
            }
            openSource();
            phase = 1;
            elapsed = 0;
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
