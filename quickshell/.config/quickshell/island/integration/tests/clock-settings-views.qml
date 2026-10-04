import QtQuick
import QtTest
import Quickshell
import "../../island"
import "../../views"
import "../../core"
import "../../services"
import "../../styles"

ShellRoot {
    id: root
    property int phase: 0
    property int elapsed: 0
    property int scenario: 0
    property var baseline: []
    readonly property int fontSize: [8, 18, 40][Math.floor(scenario / 2)]
    readonly property bool meridian: scenario % 2 === 1

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

    function clockCenter(panel) {
        const label = named(panel, "clock-label");
        return label.mapToItem(window.contentItem, label.width / 2, label.height / 2);
    }

    function checkPosition() {
        [first, second].forEach((panel, index) => {
            const point = clockCenter(panel);
            check(Math.abs(point.x - baseline[index].x) <= 1,
                "Clock stays centered on " + panel.monitorName + " in phase " + phase + ", font " + fontSize
                + ": " + point.x + "," + point.y + " expected " + baseline[index].x + "," + baseline[index].y);
            const group = named(panel, "expanded-clock-group");
            if (group) {
                const center = group.mapToItem(panel, group.width / 2, group.height / 2);
                check(Math.abs(center.y - panel.height / 2) <= 1, "Clock/date group keeps its original vertical alignment");
            }
        });
    }

    function click(item) {
        check(input.mouseClick(item, item.width / 2, item.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Deliver pointer click");
    }

    function next() {
        phase++;
        elapsed = 0;
    }

    function configure() {
        ThemeService.setSetting("clockFontSize", fontSize);
        ThemeService.setSetting("clock12Hour", meridian);
        next();
    }

    function checkFormat(meridian) {
        const label = named(sample, "clock-label");
        [[0, "00:05", "12:05 AM"], [12, "12:05", "12:05 PM"], [23, "23:05", "11:05 PM"]].forEach(example => {
            sample.currentTime = new Date(2026, 9, 3, example[0], 5);
            check(label.text === example[meridian ? 2 : 1], "Format midnight, noon, and evening: " + label.text);
        });
        [first, second, settings].forEach(item => {
            const text = named(item, "clock-label").text;
            check(text === Qt.formatTime(new Date(), meridian ? "h:mm AP" : "HH:mm"), "All clocks and preview update immediately");
        });
        check(named(settings, "clock-format-toggle").checked === meridian, "Settings switch stays synchronized");
    }

    function tick() {
        elapsed += 40;
        switch (phase) {
        case 0:
            if (!ThemeService.ready) return;
            StatusManager.visible = false;
            configure();
            break;
        case 1:
            if (ThemeService.busy || ThemeService.settings.clockFontSize !== fontSize
                || ThemeService.settings.clock12Hour !== meridian) return;
            IslandController.reset();
            next();
            break;
        case 2:
            if (elapsed < Theme.animationNormal + 80) return;
            baseline = [clockCenter(first), clockCenter(second)];
            IslandController.toggleMode(IslandState.expandedMode, [], first.monitorName);
            next();
            break;
        case 3:
            checkPosition();
            if (elapsed < Theme.animationNormal + 80) return;
            check(first.height > IslandGeometry.compactHeight && first.width >= 520, "Menu expands around clock");
            IslandController.toggleMode(IslandState.expandedMode, [], second.monitorName);
            next();
            break;
        case 4:
            checkPosition();
            if (elapsed < Theme.animationNormal + 80) return;
            check(first.height === IslandGeometry.compactHeight && second.height > IslandGeometry.compactHeight, "Transfer preserves panel routing");
            IslandController.toggleMode(IslandState.expandedMode, [], second.monitorName);
            next();
            break;
        case 5:
            checkPosition();
            if (elapsed < Theme.animationNormal + 80) return;
            check(second.height === IslandGeometry.compactHeight, "Second toggle closes menu");
            scenario++;
            if (scenario < 6) { phase = 0; configure(); return; }
            ThemeService.setSetting("clockFontSize", 18);
            ThemeService.setSetting("clock12Hour", false);
            next();
            break;
        case 6:
            if (ThemeService.busy || ThemeService.settings.clock12Hour || ThemeService.settings.clockFontSize !== 18) return;
            checkFormat(false);
            IslandController.toggleMode(IslandState.expandedMode, [], first.monitorName);
            next();
            break;
        case 7:
            if (elapsed < Theme.animationNormal + 80) return;
            click(named(first, "clock-format-button"));
            check(IslandState.mode === IslandState.expandedMode && !IslandState.islandPinned, "Clock click preserves menu and pin state");
            next();
            break;
        case 8:
            if (ThemeService.busy || !ThemeService.settings.clock12Hour) return;
            checkFormat(true);
            const toggle = named(settings, "clock-format-toggle");
            check(input.mouseClick(toggle, toggle.width - 25, toggle.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Click settings switch");
            next();
            break;
        case 9:
            if (ThemeService.busy || ThemeService.settings.clock12Hour) return;
            checkFormat(false);
            IslandController.reset();
            next();
            break;
        case 10:
            if (elapsed < Theme.animationNormal + 80) return;
            click(named(first, "clock-format-button"));
            check(IslandState.mode === IslandState.defaultMode && !IslandState.islandPinned, "Compact clock click does not pin or open menu");
            next();
            break;
        case 11:
            if (ThemeService.busy || !ThemeService.settings.clock12Hour) return;
            checkFormat(true);
            console.log("PASS: centered clocks, original vertical alignment, monitor transfers, actual pointer clicks, settings synchronization, and midnight/noon formatting");
            Qt.quit();
        }
    }

    TestEvent { id: input }
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 1400
        implicitHeight: 750
        Item { width: 700; height: 100; Island { id: first; monitorName: "HDMI-A-1"; anchors.horizontalCenter: parent.horizontalCenter } }
        Item { x: 700; width: 700; height: 100; Island { id: second; monitorName: "DP-1"; anchors.horizontalCenter: parent.horizontalCenter } }
        ClockSettingsView { id: settings; x: 800; y: 120 }
        ClockView { id: sample; interactive: false; y: 200 }
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
