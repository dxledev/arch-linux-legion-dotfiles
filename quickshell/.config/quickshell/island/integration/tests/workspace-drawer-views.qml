import QtQuick
import QtTest
import Quickshell
import "../../island"
import "../../core"
import "../../services"
import "../../styles"

ShellRoot {
    id: root
    property int phase: 0
    property int elapsed: 0
    property int activeMonitor: 0
    property real clockY: 0
    property real reservation: 0

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }

    function named(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const found = named(child, name);
            if (found) return found;
        }
        return null;
    }

    function settings(values) {
        ThemeService.settings = Object.assign({}, ThemeService.settings, values);
    }

    function showWorkspace(monitor, title) {
        StatusManager.show({mode: "workspace", monitorName: monitor, icon: "", title: title, value: Number(title)});
    }

    function next() { phase++; elapsed = 0; }

    function checkSurface() {
        const shape = named(first, "status-attached-surface");
        check(shape.join > 0 && shape.foot > 0, "Concave attachment and rounded lower corners");
        check(shape.surfaceColor.a === first.surfaceColor.a && shape.borderWidth === 2, "Drawer shares opacity and border");
        const image = capture.grabImage(first);
        image.save(Quickshell.env("WORKSPACE_DRAWER_IMAGE"));
        const center = Math.floor(first.width / 2);
        const seam = Math.floor(first.panelHeight);
        check(Math.abs(image.pixel(center, 5).a - 0.55) < 0.02, "Header renders its opacity once");
        check(Math.abs(image.pixel(center, seam).a - 0.55) < 0.02, "No doubled opacity or border across attachment");
        check(image.pixel(20, seam + 20).a === 0, "Space beside drawer is transparent");
        const left = Math.floor(shape.drawerLeft);
        check(image.pixel(left - 8, seam + 8).a < 0.1, "Outside concave join is transparent");
        check(image.pixel(left - 2, seam + 2).a > 0.4, "Concave join connects to bottom edge");
    }

    function tick() {
        elapsed += 40;
        switch (phase) {
        case 0:
            if (!ThemeService.ready) return;
            settings({islandAnimationDuration: 0, workspaceAnimationDuration: 160, hoverToExpand: false,
                workspaceStyle: "default", opacity: 0.55, islandBorderWidth: 2});
            StatusManager.visible = false;
            IslandController.openExpanded("HDMI-A-1");
            IslandState.islandPinned = true;
            next();
            break;
        case 1:
            if (elapsed < 100) return;
            check(first.height === 75 && second.mode === IslandState.defaultMode, "Expanded header stays on its monitor");
            clockY = named(first, "expanded-clock-group").mapToItem(first, 0, 0).y;
            reservation = IslandGeometry.reservedHeight;
            showWorkspace("HDMI-A-1", "3");
            next();
            break;
        case 2:
            check(first.statusArea.reveal > 0 && first.statusArea.reveal < 1, "Animate drawer downward");
            check(first.height > 75 && first.height < 75 + IslandGeometry.compactHeight + 8, "Drawer grows below expanded header");
            check(Math.abs(first.panelHeight - 75) < 0.01, "Header keeps its original height during reveal");
            check(Math.abs(named(first, "expanded-clock-group").mapToItem(first, 0, 0).y - clockY) < 0.01, "Clock stays in place");
            next();
            break;
        case 3:
            if (elapsed < 220) return;
            check(first.statusArea.reveal === 1 && first.statusArea.y === 75, "Drawer attaches to expanded bottom edge");
            check(named(first, "expanded-status-chip") === null, "Workspace number no longer uses the header chip");
            check(named(first, "workspace-label").text === "Workspace 3", "Default workspace label appears in drawer");
            check(!second.statusDrawerOpen && second.statusDrawerHeight === 0, "No drawer on other monitor");
            check(IslandGeometry.reservedHeight === reservation, "Drawer leaves desktop reservation stable");
            checkSurface();
            settings({workspaceStyle: "dots", workspaceCount: 20, workspaceDotSize: 31});
            next();
            break;
        case 4:
            if (elapsed < 160) return;
            check(!named(first, "workspace-label").visible && named(first, "workspace-dot-1") !== null, "Dots style appears in attached drawer");
            check(first.statusDrawerWidth + 2 * first.radius < first.width, "Wide dots keep clearance for attachment corners");
            const lastDot = named(first, "workspace-dot-20");
            const lastPoint = lastDot.mapToItem(first.statusArea, lastDot.width, 0);
            check(lastPoint.x <= first.statusArea.width, "Large persistent dot rows fit without clipping");
            settings({workspaceStyle: "default", workspaceDotSize: 8});
            StatusManager.visible = false;
            next();
            break;
        case 5:
            check(first.statusArea.reveal > 0 && first.statusArea.reveal < 1, "Animate drawer retraction");
            showWorkspace("HDMI-A-1", "4");
            next();
            break;
        case 6:
            if (elapsed < 220) return;
            check(first.statusArea.reveal === 1 && named(first, "workspace-label").text === "Workspace 4", "New event reverses pending retraction");
            activeMonitor = 1;
            showWorkspace("DP-1", "10");
            next();
            break;
        case 7:
            if (elapsed < 220) return;
            check(first.height === 75 && first.mode === IslandState.expandedMode, "Other monitor event retracts drawer without moving pinned panel");
            check(!first.statusDrawerOpen && !second.statusDrawerOpen, "Compact monitor uses OSD, with no attached drawer");
            check(named(second, "compact-status").opacity === 1 && named(second, "compact-clock").opacity === 0, "Compact Island keeps normal workspace OSD");
            showWorkspace("HDMI-A-1", "5");
            next();
            break;
        case 8:
            if (elapsed < 220) return;
            check(first.statusDrawerOpen, "Drawer remains on panel owner after focus changes");
            StatusManager.show({mode: "volume", monitorName: "HDMI-A-1", icon: "", title: "50%", value: 50});
            next();
            break;
        case 9:
            if (elapsed < 220) return;
            check(first.statusDrawerOpen && named(first, "osd-percentage").text === "50%", "Volume replaces workspace in the shared drawer");
            activeMonitor = 0;
            settings({workspaceAnimationDuration: 0});
            showWorkspace("HDMI-A-1", "6");
            next();
            break;
        case 10:
            if (elapsed < 100) return;
            check(first.statusArea.reveal === 1, "Zero duration opens drawer immediately");
            IslandController.reset();
            next();
            break;
        case 11:
            if (elapsed < 100) return;
            check(first.statusDrawerHeight === 0 && first.height === IslandGeometry.compactHeight, "Closing Island resumes compact workspace OSD");
            check(named(first, "compact-status").opacity === 1, "Existing workspace status survives closing header");
            IslandController.openExpanded("HDMI-A-1");
            next();
            break;
        case 12:
            if (elapsed < 1800) return;
            check(!StatusManager.visible && first.height === 75 && first.statusArea.reveal === 0, "Status expiry retracts drawer and preserves header");
            console.log("PASS: attached workspace drawer, concave joins, shared opacity and border, stationary header, styles, wide dot rows, bidirectional animations, monitor ownership, compact OSD, and expiry");
            Qt.quit();
        }
    }

    TestResult { id: capture }
    FloatingWindow {
        visible: true
        color: "transparent"
        implicitWidth: 1600
        implicitHeight: 240
        Island { id: first; x: 20; y: 10; monitorName: "HDMI-A-1"; monitorActive: root.activeMonitor === 0 }
        Island { id: second; x: 1100; y: 10; monitorName: "DP-1"; monitorActive: root.activeMonitor === 1 }
    }
    Timer {
        interval: 40
        running: true
        repeat: true
        onTriggered: {
            try { root.tick(); }
            catch (error) { console.error("FAIL: phase " + root.phase + ": " + error); Qt.quit(); }
        }
    }
}
