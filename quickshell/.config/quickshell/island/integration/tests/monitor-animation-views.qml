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
    readonly property var panel: scenario < 2 ? first : second
    readonly property var otherPanel: scenario < 2 ? second : first
    readonly property bool switchMonitor: scenario % 2 === 1
    property real expandedWidth: 0
    property real expandedHeight: 0

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }

    function interaction(item) {
        if (item.handleHoverChanged !== undefined) return item;
        for (const child of item.children) {
            const found = interaction(child);
            if (found) return found;
        }
        return null;
    }

    function next() {
        phase++;
        elapsed = 0;
    }

    function openPanel() {
        activeMonitor = scenario < 2 ? 0 : 1;
        IslandController.openExpanded(panel.monitorName);
    }

    function expectClosing() {
        check(IslandState.mode === IslandState.defaultMode, "Close delay elapsed");
        check(panel.height > IslandGeometry.compactHeight && panel.height < expandedHeight,
            "Height closes gradually on " + panel.monitorName + ", switched monitor: " + switchMonitor);
        check(panel.width !== expandedWidth && Math.abs(panel.width - panel.implicitWidth) < 0.01,
            "Width follows its animation after closing");
        check(Math.abs(panel.height - panel.implicitHeight) < 0.01,
            "Height follows its animation after closing");
        check(otherPanel.height === IslandGeometry.compactHeight, "Other monitor stays compact");
    }

    function tick() {
        elapsed += 40;
        switch (phase) {
        case 0:
            if (!ThemeService.ready) return;
            ThemeService.settings = {hoverDelay: 80, collapseDelay: 100};
            StatusManager.visible = false;
            IslandController.reset();
            openPanel();
            next();
            break;
        case 1:
            if (elapsed < Theme.animationNormal + 100) return;
            expandedWidth = panel.width;
            expandedHeight = panel.height;
            check(expandedHeight > IslandGeometry.compactHeight, "Panel expanded");
            interaction(panel).handleHoverChanged(true);
            if (switchMonitor) activeMonitor = activeMonitor === 0 ? 1 : 0;
            else interaction(panel).handleHoverChanged(false);
            next();
            break;
        case 2:
            if (elapsed < 100) check(IslandState.mode === IslandState.expandedMode, "Preserve close delay");
            if (elapsed < 160) return;
            expectClosing();
            next();
            break;
        case 3:
            if (elapsed < Theme.animationNormal + 100) return;
            check(panel.height === IslandGeometry.compactHeight, "Close animation finishes");
            scenario++;
            if (scenario === 4) {
                console.log("PASS: normal close animation on both monitors before and after focus changes");
                Qt.quit();
                return;
            }
            openPanel();
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
