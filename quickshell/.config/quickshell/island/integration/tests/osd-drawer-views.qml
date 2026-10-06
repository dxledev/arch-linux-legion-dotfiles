import QtQuick
import QtTest
import Quickshell
import "../../island"
import "../../core"
import "../../services"

ShellRoot {
    id: root
    property int phase: 0
    property int elapsed: 0
    property int scenario: 0
    property real clockY: 0
    property real headerWidth: 0
    property real headerHeight: 0
    property var headerImage: null
    property bool verifyHeader: false
    property int panelScenario: 0
    readonly property var panelScenarios: [
        {name: "Expanded", mode: IslandState.expandedMode},
        {name: "Power", mode: IslandState.powerMenuMode},
        {name: "Control center", mode: IslandState.controlCenterMode},
        {name: "Themes", mode: IslandState.themeSelectorMode},
        {name: "Wallpapers", mode: IslandState.wallpaperSelectorMode},
        {name: "Media", mode: IslandState.mediaControlsMode},
        {name: "Settings", mode: IslandState.settingsMode},
        {name: "Shell switcher", mode: IslandState.shellSwitcherMode},
        {name: "Navigation", mode: IslandState.navigationMode},
        {name: "Notifications", mode: IslandState.notificationsMode},
        {name: "Audio devices", mode: IslandState.audioDevicesMode},
        {name: "Clock settings", mode: IslandState.clockSettingsMode},
        {name: "OSD settings", mode: IslandState.osdSettingsMode},
        {name: "Launcher", mode: IslandState.launcherMode},
        {name: "System", mode: IslandState.systemMode}
    ].concat(IslandController.settingsSections.map(section => ({
        name: "Settings / " + section, mode: IslandState.settingsSectionMode, section: section
    })))
    readonly property var events: [
        {mode: "volume", title: "65%", value: 65, icon: ""},
        {mode: "brightness", title: "25%", value: 25, icon: "󰃞", label: "HDMI-A-1"},
        {mode: "nightlight", title: "Nightlight On", value: true, icon: "󰖔"},
        {mode: "keyboard", title: "English", value: "EN", icon: "󰌌"},
        {mode: "workspace", title: "3", value: 3, icon: ""},
        {mode: "keyboard", title: "English International Extended Keyboard Layout", value: "EN", icon: "󰌌"}
    ]

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }

    function named(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const found = named(child, name);
            if (found) return found;
        }
        return null;
    }

    function effectiveVisible(item) {
        for (let current = item; current; current = current.parent)
            if (!current.visible || current.opacity === 0) return false;
        return !!item;
    }

    function visiblePanels() {
        return [first, second].filter(capsule => effectiveVisible(named(capsule, "compact-status"))
            || effectiveVisible(named(capsule.statusArea, "volume-osd"))
            || effectiveVisible(named(capsule.statusArea, "brightness-osd"))
            || effectiveVisible(named(capsule.statusArea, "text-osd"))
            || effectiveVisible(named(capsule.statusArea, "workspace-label"))).length;
    }

    function show(data, monitor = "HDMI-A-1") {
        StatusManager.show(Object.assign({}, data, {monitorName: monitor}));
        check(visiblePanels() <= 1, "Only one OSD panel during immediate replacement");
    }

    function next() { phase++; elapsed = 0; }

    function checkHeaderSteady() {
        if (!verifyHeader) return;
        check(Math.abs(first.width - headerWidth) < 0.01, "Parent width stays fixed throughout OSD animation: " + first.width + " / " + headerWidth);
        check(Math.abs(first.panelHeight - headerHeight) < 0.01, "Parent height stays fixed throughout OSD animation: " + first.panelHeight);
        if (first.mode === IslandState.expandedMode)
            check(Math.abs(named(first, "expanded-clock-group").mapToItem(first, 0, 0).y - clockY) < 0.01, "Clock stays steady on every animation frame");
    }

    function checkHeaderPixels() {
        const currentImage = capture.grabImage(first);
        for (let y = 0; y < Math.floor(headerHeight) - 4; y++) {
            for (let x = 0; x < 26; x++) {
                for (const column of [x, headerImage.width - x - 1]) {
                    const before = headerImage.pixel(column, y);
                    const after = currentImage.pixel(column, y);
                    check(Math.abs(before.a - after.a) < 0.03 && Math.abs(before.r - after.r) < 0.03,
                        "Parent outline stays visually steady at " + column + "," + y);
                }
            }
        }
    }

    function captureHeader() {
        headerWidth = first.width;
        headerHeight = first.panelHeight;
        headerImage = capture.grabImage(first);
        if (first.mode === IslandState.expandedMode)
            clockY = named(first, "expanded-clock-group").mapToItem(first, 0, 0).y;
        verifyHeader = true;
    }

    function openPanel() {
        const data = panelScenarios[panelScenario];
        verifyHeader = false;
        StatusManager.visible = false;
        IslandState.settingsSection = data.section ?? "";
        IslandController.setMode(data.mode, "HDMI-A-1");
        elapsed = 0;
    }

    function checkPanelDrawer() {
        const name = panelScenarios[panelScenario].name;
        check(first.statusDrawerOpen && first.statusArea.reveal === 1, name + " shows attached " + StatusManager.mode + " OSD");
        check(first.statusArea.y === headerHeight && first.height > headerHeight, name + " attaches OSD below its own bottom edge");
        check(named(first, "status-attached-surface").join > 0, name + " has concave attachment corners");
        check(visiblePanels() === 1 && !second.statusDrawerOpen, name + " preserves exclusive OSD monitor routing");
        checkHeaderPixels();
    }

    function checkDrawer() {
        check(first.statusDrawerOpen && first.statusArea.reveal === 1, "OSD uses expanded drawer: " + StatusManager.mode);
        check(first.panelHeight === 75 && first.statusArea.y === 75, "Header stays fixed above OSD");
        check(Math.abs(named(first, "expanded-clock-group").mapToItem(first, 0, 0).y - clockY) < 0.01, "Clock stays in place across OSD changes");
        check(visiblePanels() === 1 && !second.statusDrawerOpen, "Exactly one OSD across monitors");
        check(named(first, "status-attached-surface").join > 0, "Each OSD has concave attachment corners");
        checkHeaderPixels();
        const data = events[scenario];
        if (data.mode === "volume")
            check(named(first.statusArea, "osd-percentage").text === "65%", "Volume uses its slider and percentage");
        if (data.mode === "brightness")
            check(StatusManager.brightnessEvents.length === 1 && StatusManager.brightnessEvents[0].value === 25, "Brightness uses one current event");
        if (data.mode === "nightlight" || data.mode === "keyboard")
            check(named(first.statusArea, "status-label").text === data.title, "Latest text OSD replaces slider");
        capture.grabImage(first).save(Quickshell.env("OSD_DRAWER_IMAGE_DIR") + "/" + data.mode + ".png");
    }

    function tick() {
        elapsed += 40;
        check(visiblePanels() <= 1, "At most one OSD throughout animations");
        switch (phase) {
        case 0:
            if (!ThemeService.ready) return;
            ThemeService.islandScreens = [{name: "HDMI-A-1"}, {name: "DP-1"}];
            ThemeService.settings = Object.assign({}, ThemeService.settings, {islandAnimationDuration: 300,
                osdAnimationDuration: 160, osdTimeout: 600, workspaceAnimationDuration: 160,
                hoverToExpand: false, workspaceStyle: "default", opacity: 0.65, islandBorderWidth: 2});
            StatusManager.visible = false;
            IslandController.openExpanded("HDMI-A-1");
            IslandState.islandPinned = true;
            next();
            break;
        case 1:
            if (elapsed < 400) return;
            captureHeader();
            show(events[scenario]);
            next();
            break;
        case 2:
            if (elapsed < 220) return;
            checkDrawer();
            scenario++;
            if (scenario < events.length) { show(events[scenario]); elapsed = 0; return; }
            show({mode: "brightness", title: "30%", value: 30, icon: "󰃟"});
            show({mode: "brightness", title: "80%", value: 80, icon: "󰃠"}, "DP-1");
            check(StatusManager.brightnessEvents.length === 1 && StatusManager.brightnessEvents[0].value === 80, "Second monitor brightness replaces first event");
            check(!first.statusDrawerOpen && StatusManager.isTargetScreen(second.monitorName), "OSD ownership moves to latest event monitor");
            next();
            break;
        case 3:
            if (elapsed < 220) return;
            check(visiblePanels() === 1 && first.height === 75, "Previous drawer retracts and other monitor uses compact OSD");
            ThemeService.islandScreens = [{name: "HDMI-A-1"}];
            show({mode: "brightness", title: "40%", value: 40, icon: "󰃟", label: "DP-1"}, "DP-1");
            next();
            break;
        case 4:
            if (elapsed < 220) return;
            check(first.statusDrawerOpen && visiblePanels() === 1, "Unavailable source monitor falls back to the sole Island");
            check(named(named(first.statusArea, "brightness-osd"), "osd-monitor-label").text === "DP-1", "Fallback brightness keeps source monitor label");
            show(events[0]);
            next();
            break;
        case 5:
            if (elapsed < 400) return;
            show(events[3]);
            check(StatusManager.brightnessEvents.length === 0, "Other OSD types clear old brightness event");
            next();
            break;
        case 6:
            if (elapsed < 400) return;
            check(StatusManager.visible && first.statusDrawerOpen, "Replacement restarts its full display timeout");
            next();
            break;
        case 7:
            if (elapsed < 400) return;
            check(!StatusManager.visible && visiblePanels() === 0 && first.height === 75, "Latest OSD expires without reviving earlier panels");
            show(events[0]);
            verifyHeader = false;
            IslandController.reset();
            next();
            break;
        case 8:
            if (elapsed < 400) return;
            check(first.statusDrawerHeight === 0 && first.height >= 33 && first.height < 75, "Compact mode uses normal OSD geometry");
            check(visiblePanels() === 1 && named(first, "compact-status").visible, "Closing header transfers current OSD into compact Island");
            openPanel();
            next();
            break;
        case 9:
            if (elapsed < 400) return;
            captureHeader();
            show(events[0]);
            next();
            break;
        case 10:
            if (elapsed < 220) return;
            checkPanelDrawer();
            show(events[4]);
            next();
            break;
        case 11:
            if (elapsed < 220) return;
            checkPanelDrawer();
            capture.grabImage(first).save(Quickshell.env("OSD_DRAWER_IMAGE_DIR") + "/panel-" + panelScenario + ".png");
            StatusManager.visible = false;
            next();
            break;
        case 12:
            if (elapsed < 220) return;
            check(first.height === headerHeight && visiblePanels() === 0, "OSD retracts without resizing " + panelScenarios[panelScenario].name);
            checkHeaderPixels();
            panelScenario++;
            if (panelScenario < panelScenarios.length) {
                openPanel();
                phase = 9;
                break;
            }
            console.log("PASS: all OSD types share attached concave drawer on every panel and settings section, steady parent geometry and outline, single latest panel across monitors, brightness replacement, fallback labels, restarted expiry, and compact OSD behavior");
            Qt.quit();
        }
    }

    TestResult { id: capture }
    FrameAnimation {
        running: root.verifyHeader
        onTriggered: {
            try { root.checkHeaderSteady(); }
            catch (error) { console.error("FAIL: steady parent: " + error); root.verifyHeader = false; Qt.quit(); }
        }
    }
    FloatingWindow {
        visible: true
        color: "transparent"
        implicitWidth: 1200
        implicitHeight: 900
        Island { id: first; x: 20; y: 10; monitorName: "HDMI-A-1" }
        Island { id: second; x: 700; y: 10; monitorName: "DP-1"; monitorActive: false }
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
