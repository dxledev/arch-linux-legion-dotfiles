pragma ComponentBehavior: Bound
import QtQuick
import QtTest
import Quickshell
import "../../components"
import "../../core"
import "../../island"
import "../../services"
import "../../styles"
import "../../views"

ShellRoot {
    id: root
    property int phase: 0
    property int elapsed: 0
    property int scenario: 0
    readonly property int clockSize: [8, 18, 40][Math.floor(Math.min(scenario, 5) / 2)]
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

    function next() { phase++; elapsed = 0; }

    function click(item, x) {
        check(input.mouseClick(item, x ?? item.width / 2, item.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Deliver pointer click");
    }

    function moveCursor(item, x, y) {
        check(input.mouseMove(item, x, y, 0, Qt.NoButton, Qt.NoModifier), "Deliver pointer movement");
    }

    function checkClockPadding() {
        const clock = named(capsule, "clock-label");
        const point = clock.mapToItem(capsule, 0, 0);
        const positions = [];
        for (let item = clock; item && item !== capsule; item = item.parent)
            positions.push({name: item.objectName, x: item.x, width: item.width, implicit: item.implicitWidth});
        const padding = (capsule.width - clock.width) / 2 - capsule.border.width;
        check(padding >= 2 && padding < 2.6, "Clock keeps 2 px of padding at its minimum width: " + padding);
        check(Math.abs(point.x - (capsule.width - clock.width) / 2) <= 0.6,
            "Clock remains centered: " + point.x + " / " + (capsule.width - clock.width) / 2 + " " + JSON.stringify(positions));
        check(point.x - capsule.border.width >= 2 && capsule.width - point.x - clock.width - capsule.border.width >= 2,
            "Both clock edges keep their minimum padding: left=" + (point.x - capsule.border.width)
            + ", right=" + (capsule.width - point.x - clock.width - capsule.border.width)
            + ", width=" + capsule.width + ", text=" + clock.width + ", x=" + point.x);
        check(capsule.height >= clock.height + 4 + 2 * capsule.border.width, "Clock fits the compact height and border");
        if (clockSize <= 18 && capsule.border.width === 0)
            check(capsule.width < 160, "Width can shrink below the original 160 px floor");
    }

    function tick() {
        elapsed += 40;
        switch (phase) {
        case 0:
            if (!ThemeService.ready || ThemeService.busy) return;
            const ui = named(settings, "appearance-ui-section");
            const island = named(settings, "appearance-island-section");
            check(ui.title === "UI" && island.title === "Island" && ui.y < island.y, "UI comes before Island");
            check(named(ui, "setting-choice-Font") !== null && named(island, "setting-choice-Font") === null, "Font belongs to UI");
            check(named(island, "setting-slider-reservedSpaceBelow").parent.label === "Bottom margin", "Bottom margin label");
            check(capsule.width === 160 && capsule.height === 33 && capsule.border.width === 0, "Original default geometry");
            const boldToggle = named(ui, "appearance-bold-toggle");
            click(boldToggle, boldToggle.width - 25);
            ThemeService.setSetting("uiLetterSpacing", 1.25);
            ThemeService.setSetting("uiAnimationDuration", 500);
            ThemeService.setSetting("islandAnimationDuration", 0);
            ThemeService.setSetting("islandWidth", 4);
            next();
            break;
        case 1:
            if (ThemeService.busy || !ThemeService.settings.uiFontBold || ThemeService.settings.islandWidth !== 4) return;
            check(sample.font.bold && sample.font.letterSpacing === 1.25, "UI text updates bold and letter spacing");
            check(Theme.animationNormal === 500 && Theme.animationFast === 300, "UI animations follow their duration");
            ThemeService.setSetting("clockFontSize", clockSize);
            ThemeService.setSetting("clock12Hour", meridian);
            next();
            break;
        case 2:
            if (ThemeService.busy || ThemeService.settings.clockFontSize !== clockSize || ThemeService.settings.clock12Hour !== meridian || elapsed < 100) return;
            checkClockPadding();
            scenario++;
            if (scenario < 6) { phase = 1; elapsed = 0; return; }
            ThemeService.setSetting("clockInheritUiFont", true);
            ThemeService.setSetting("uiFontFamily", "DejaVu Sans");
            ThemeService.setSetting("islandBorderWidth", 4);
            ThemeService.setSetting("islandHeight", 24);
            next();
            break;
        case 3:
            if (ThemeService.busy || ThemeService.settings.islandBorderWidth !== 4 || elapsed < 100) return;
            checkClockPadding();
            check(named(capsule, "clock-label").font.family === "DejaVu Sans", "Width follows the inherited UI font");
            check(capsule.border.width === 4 && named(capsule, "status-attached-surface").borderColor === Theme.border, "Island border follows theme");
            check(IslandGeometry.compactHeight >= IslandGeometry.minimumHeight && IslandGeometry.compactHeight > 24,
                "Small heights grow to fit large clock fonts");
            ThemeService.setSetting("islandHeight", 60);
            ThemeService.setSetting("topMargin", 20);
            ThemeService.setSetting("reservedSpaceBelow", 18);
            next();
            break;
        case 4:
            if (ThemeService.busy || ThemeService.settings.reservedSpaceBelow !== 18 || elapsed < 100) return;
            check(capsule.height === 60 && IslandGeometry.reservedHeight === 98, "Height and margins update desktop reservation");
            const slider = named(settings, "setting-slider-islandWidth");
            const scroll = named(settings, "settings-panel-scroll");
            scroll.contentY = slider.mapToItem(scroll.contentItem, 0, 0).y - 70;
            next();
            break;
        case 5:
            if (elapsed < 80) return;
            const widthSlider = named(settings, "setting-slider-islandWidth");
            click(widthSlider, widthSlider.width * 0.65);
            next();
            break;
        case 6:
            if (ThemeService.busy || ThemeService.settings.islandWidth === 4 || elapsed < 100) return;
            check(capsule.width === ThemeService.settings.islandWidth, "Actual width slider saves and resizes the Island");
            check(settings.implicitHeight <= 650, "Appearance stays within its scrollable panel");
            const settingsScroll = named(settings, "settings-panel-scroll");
            settingsScroll.contentY = settingsScroll.contentHeight - settingsScroll.height;
            next();
            break;
        case 7:
            if (elapsed < 80) return;
            const expandToggle = named(settings, "island-hover-expand-toggle");
            click(expandToggle, expandToggle.width - 25);
            ThemeService.setSetting("hoverDelay", 0);
            ThemeService.setSetting("collapseDelay", 0);
            next();
            break;
        case 8:
            if (ThemeService.busy || ThemeService.settings.hoverToExpand || elapsed < 80) return;
            moveCursor(capsule, capsule.width / 2, capsule.height / 2);
            next();
            break;
        case 9:
            if (elapsed < 160) return;
            check(IslandState.mode === IslandState.defaultMode, "Hover leaves compact Island closed when disabled");
            click(named(capsule, "clock-label"));
            next();
            break;
        case 10:
            if (elapsed < 100) return;
            check(IslandState.mode === IslandState.expandedMode && IslandState.islandPinned && IslandState.panelMonitorName === "test",
                "Click directly on the clock expands and pins this monitor's Island");
            check(ThemeService.settings.clock12Hour, "Compact expansion click preserves the clock format");
            moveCursor(window.contentItem, 1150, 700);
            next();
            break;
        case 11:
            if (elapsed < 100) return;
            check(IslandState.mode === IslandState.expandedMode, "Click-opened Island stays open when the cursor leaves");
            IslandController.reset();
            ThemeService.setSetting("hoverToExpand", true);
            next();
            break;
        case 12:
            if (ThemeService.busy || !ThemeService.settings.hoverToExpand || elapsed < 100) return;
            moveCursor(capsule, capsule.width / 2, capsule.height / 2);
            next();
            break;
        case 13:
            if (elapsed < 100) return;
            check(IslandState.mode === IslandState.expandedMode && !IslandState.islandPinned, "Enabled hover expands without pinning");
            console.log("PASS: appearance sections, clock padding, saved slider changes, typography, borders, height and reserved margins");
            Qt.quit();
        }
    }

    TestEvent { id: input }
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 1200
        implicitHeight: 760
        Island { id: capsule; monitorName: "test"; x: 620; y: 30 }
        AppearanceSettingsView { id: settings; x: 20; y: 20; width: implicitWidth; height: implicitHeight }
        UiText { id: sample; text: "UI sample"; x: 650; y: 200; font.pixelSize: 14 }
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
