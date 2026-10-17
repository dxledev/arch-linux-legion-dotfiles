import QtQuick
import QtTest
import Quickshell
import "../../island"
import "../../core"
import "../../services"
import "../../services/FocusNavigation.js" as FocusNavigation

// Drives every panel from the keyboard through the real Island: opens it the way a key binding does,
// walks it with the arrows, closes it with Escape and climbs the breadcrumbs with the controller's goBack.
ShellRoot {
    id: root

    property int caseIndex: 0
    property int phase: 0
    property int elapsed: 0
    property int pressIndex: 0
    property string startFocus: ""
    property var seenFocus: []
    property var gaps: []
    readonly property string monitor: "HDMI-A-1"
    readonly property var presses: [Qt.Key_Down, Qt.Key_Down, Qt.Key_Down, Qt.Key_Right, Qt.Key_Right, Qt.Key_Up]
    // own: panels that drive a highlighted list or grid with their own arrow handling, where focus stays on one field.
    readonly property var cases: [
        { name: "launcher", own: true, listDriven: true, mode: IslandState.launcherMode },
        { name: "libreoffice", own: true, listDriven: true, mode: IslandState.libreOfficeMode, back: IslandState.launcherMode },
        { name: "navigation", mode: IslandState.navigationMode, back: IslandState.expandedMode },
        { name: "settings", mode: IslandState.settingsMode, back: IslandState.navigationMode },
        { name: "clock-settings", mode: IslandState.clockSettingsMode, back: IslandState.settingsMode },
        { name: "osd-settings", mode: IslandState.osdSettingsMode, back: IslandState.settingsMode },
        { name: "shell-switcher", own: true, listDriven: true, mode: IslandState.shellSwitcherMode, back: IslandState.navigationMode },
        { name: "layout", own: true, listDriven: true, mode: IslandState.layoutSwitcherMode, back: IslandState.navigationMode },
        { name: "power-menu", own: true, listDriven: true, mode: IslandState.powerMenuMode },
        { name: "control-center", mode: IslandState.controlCenterMode, back: IslandState.expandedMode },
        { name: "theme-selector", own: true, listDriven: true, mode: IslandState.themeSelectorMode, back: IslandState.navigationMode },
        { name: "wallpaper-selector", own: true, listDriven: true, mode: IslandState.wallpaperSelectorMode, back: IslandState.navigationMode },
        { name: "media", mode: IslandState.mediaControlsMode },
        { name: "notifications", mode: IslandState.notificationsMode, back: IslandState.controlCenterMode },
        { name: "audio-devices", mode: IslandState.audioDevicesMode, back: IslandState.controlCenterMode },
        { name: "system", mode: IslandState.systemMode, back: IslandState.navigationMode },
        { name: "ai-usage", mode: IslandState.aiUsageMode, back: IslandState.navigationMode },
        { name: "wifi", mode: IslandState.wifiMode, back: IslandState.controlCenterMode },
        { name: "bluetooth", mode: IslandState.bluetoothMode, back: IslandState.controlCenterMode },
        { name: "clipboard", own: true, listDriven: true, mode: IslandState.clipboardMode, back: IslandState.navigationMode },
        { name: "chromack", own: true, mode: IslandState.chromackMode, back: IslandState.navigationMode },
        { name: "wallhaven", own: true, mode: IslandState.wallhavenMode, back: IslandState.navigationMode },
        { name: "calendar", own: true, listDriven: true, mode: IslandState.calendarMode, back: IslandState.navigationMode },
        { name: "keybinds", mode: IslandState.keybindsMode, back: IslandState.navigationMode },
        { name: "power-profile", mode: IslandState.powerProfileMode, back: IslandState.navigationMode },
        { name: "proton-vpn", mode: IslandState.protonVpnMode, back: IslandState.navigationMode },
        { name: "record-options", mode: IslandState.recordOptionsMode, back: IslandState.expandedMode },
        { name: "timer", mode: IslandState.timerMode, back: IslandState.navigationMode },
        { name: "expanded", mode: IslandState.expandedMode },
        { name: "section:launcher", section: "launcher", back: IslandState.settingsMode },
        { name: "section:menu", section: "menu", back: IslandState.settingsMode },
        { name: "section:appearance", section: "appearance", back: IslandState.settingsMode },
        { name: "section:desktop", section: "desktop", back: IslandState.settingsMode },
        { name: "section:clock", section: "clock", back: IslandState.settingsMode },
        { name: "section:lock", section: "lock", back: IslandState.settingsMode },
        { name: "section:osd", section: "osd", back: IslandState.settingsMode },
        { name: "section:workspaces", section: "workspaces", back: IslandState.settingsMode },
        { name: "section:dynamicPalette", section: "dynamicPalette", back: IslandState.settingsMode },
        { name: "section:notifications", section: "notifications", back: IslandState.settingsMode },
        { name: "section:interaction", section: "interaction", back: IslandState.settingsMode },
        { name: "section:wallpaperAnimation", section: "wallpaperAnimation", back: IslandState.settingsMode },
        { name: "section:media", section: "media", back: IslandState.settingsMode },
        { name: "section:screenRecording", section: "screenRecording", back: IslandState.settingsMode }
    ]

    function check(condition, message) { if (!condition) throw new Error(message); }

    function find(item, property) {
        if (item[property] !== undefined) return item;
        for (const child of item.children) {
            const found = find(child, property);
            if (found) return found;
        }
        return null;
    }

    function describe(item) {
        if (!item) return "none";
        const kind = item.toString().split("(")[0].split("_")[0];
        return (item.objectName || item.text || item.placeholderText || kind) + "";
    }

    function focusItem() { return island.Window.window?.activeFocusItem ?? null; }

    function openCase(spec) {
        IslandController.reset();
        if (spec.section) IslandController.toggleSettingsSection(spec.section, root.monitor);
        else IslandController.toggleMode(spec.mode, [], root.monitor);
    }

    function press(key, modifiers = Qt.NoModifier) {
        input.keyClick(key, modifiers, 0);
    }

    function tick() {
        elapsed += 40;
        if (!ThemeService.ready) return;
        const spec = root.cases[root.caseIndex];
        if (!spec) {
            if (root.gaps.length > 0) {
                for (const gap of root.gaps) console.log("NAV GAP " + gap);
                throw new Error("Panels without keyboard reach: " + root.gaps.join(", "));
            }
            checkBreadcrumbs();
            console.log("PASS: keyboard navigation");
            Qt.quit();
            return;
        }
        const host = find(island, "claimFocus");
        switch (phase) {
        case 0:
            openCase(spec);
            check(IslandState.keyboardPanel, spec.name + " takes the keyboard");
            phase = 1; elapsed = 0;
            break;
        case 1:
            if (elapsed < 700 || !host.currentView) return;
            startFocus = describe(focusItem());
            seenFocus = [];
            pressIndex = 0;
            phase = 2; elapsed = 0;
            break;
        case 2:
            if (elapsed < 120) return;
            elapsed = 0;
            if (pressIndex < presses.length) {
                press(presses[pressIndex++]);
                seenFocus.push(describe(focusItem()));
                return;
            }
            const focusable = FocusNavigation.collect(host.currentView).length;
            if (!spec.listDriven) {
                const missed = mouseOnly(host.currentView);
                if (missed.length > 0) {
                    console.log("NAV MOUSEONLY " + spec.name + ": " + missed.join(" | "));
                    gaps.push(spec.name + " (mouse-only: " + missed.join(", ") + ")");
                }
            }
            const distinct = new Set([startFocus, ...seenFocus]);
            console.log("NAV " + spec.name + " focusable=" + focusable + " start=" + startFocus + " path=" + seenFocus.join(" > "));
            if (!spec.own && focusable > 1 && distinct.size < 2)
                gaps.push(spec.name + " (arrows do not move focus)");
            if (!spec.own && focusable === 0)
                gaps.push(spec.name + " (nothing focusable)");
            press(Qt.Key_Escape);
            phase = 3; elapsed = 0;
            break;
        case 3:
            if (elapsed < 80) return;
            if (IslandState.mode !== IslandState.defaultMode)
                gaps.push(spec.name + " (Escape leaves " + IslandState.mode + " open)");
            IslandController.reset();
            if (spec.back !== undefined) {
                openCase(spec);
                phase = 4;
            } else {
                caseIndex++;
                phase = 0;
            }
            elapsed = 0;
            break;
        case 4:
            if (elapsed < 700 || !host.currentView) return;
            // With a control focused, which is what swallowed Shift+Tab for its own focus traversal.
            press(Qt.Key_Down);
            press(Qt.Key_Backtab, Qt.ShiftModifier);
            if (IslandState.mode !== spec.back)
                gaps.push(spec.name + " (Shift+Tab goes to " + IslandState.mode + ", not " + spec.back + ")");
            IslandController.reset();
            caseIndex++;
            phase = 0; elapsed = 0;
            break;
        }
    }

    // Items a pointer can press that the keyboard cannot reach: a press handler on something with no focusable
    // control at, above or below it.
    function mouseOnly(view) {
        const found = [];
        const focusableAbove = item => {
            for (let p = item; p; p = p.parent) {
                if (p.activeFocusOnTab) return true;
                if (p === view) break;
            }
            return false;
        };
        const focusableBelow = item => {
            for (const child of item.children) {
                if (child.activeFocusOnTab || focusableBelow(child)) return true;
            }
            return false;
        };
        const visit = item => {
            if (!item.visible || item.opacity <= 0 || item.width <= 0 || item.height <= 0) return;
            let pressable = false;
            for (const entry of item.data) {
                const kind = entry.toString();
                if (kind.startsWith("QQuickTapHandler") && entry.enabled && (entry.acceptedButtons & Qt.LeftButton)) pressable = true;
            }
            if (item.toString().startsWith("QQuickMouseArea") && item.enabled && (item.acceptedButtons & Qt.LeftButton)
                    && item.parent && !(item.parent.activeFocusOnTab)) pressable = true;
            if (pressable) {
                const owner = item.toString().startsWith("QQuickMouseArea") ? item.parent : item;
                if (!owner.activeFocusOnTab && !focusableAbove(owner) && !focusableBelow(owner))
                    found.push((owner.objectName || owner.toString().split("(")[0]) + "@" + Math.round(owner.mapToItem(view, 0, 0).x) + "," + Math.round(owner.mapToItem(view, 0, 0).y));
            }
            for (const child of item.children) visit(child);
        };
        visit(view);
        return found;
    }

    function checkBreadcrumbs() {
        for (const spec of root.cases) {
            if (spec.back === undefined) continue;
            IslandController.reset();
            if (spec.section) IslandController.toggleSettingsSection(spec.section, root.monitor);
            else IslandController.toggleMode(spec.mode, [], root.monitor);
            check(IslandController.goBack(), spec.name + " has a parent");
            check(IslandState.mode === spec.back, spec.name + " goes back to " + spec.back + " not " + IslandState.mode);
        }
        for (const mode of [IslandState.defaultMode, IslandState.powerMenuMode, IslandState.mediaControlsMode, IslandState.expandedMode]) {
            IslandController.reset();
            if (mode !== IslandState.defaultMode) IslandController.toggleMode(mode, [], root.monitor);
            check(!IslandController.goBack(), "Top-level mode " + mode + " has nowhere to go back to");
        }
        IslandController.reset();
        IslandController.openControlCenter();
        check(IslandState.keyboardOwned === false, "A control center opened without a key binding does not own the keyboard");
        IslandController.toggleMode(IslandState.wifiMode, [], root.monitor);
        IslandController.goBack();
        check(IslandState.mode === IslandState.controlCenterMode && IslandState.keyboardOwned,
            "Going back from a keyboard panel keeps the keyboard");
        IslandController.reset();
        check(!IslandState.keyboardOwned, "Closing releases the keyboard");
    }

    TestEvent { id: input }

    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 1100
        implicitHeight: 900
        Island {
            id: island
            monitorName: root.monitor
            monitorActive: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
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
