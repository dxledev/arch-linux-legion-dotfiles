import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../views"
import "../../core"
import "../../island"

ShellRoot {
    id: root
    property int phase: 0

    function check(condition, message) { if (!condition) throw new Error(message); }
    function named(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const found = named(child, name);
            if (found) return found;
        }
        return null;
    }

    Window {
        id: window
        visible: true
        width: 500
        height: 600
        Loader {
            id: loader
            anchors.fill: parent
            sourceComponent: LayoutSwitcherView {}
        }
    }

    TestEvent { id: input }

    function step() {
        const view = loader.item;
        check(view, "Layout view loads");
        if (phase === 0) {
            IslandController.openLayoutSwitcher();
            check(IslandState.mode === IslandState.layoutSwitcherMode, "Layout mode opens");
            check(IslandState.modal, "Layout mode is modal");
            check(view.filteredLayouts.length === 8, "All eight layouts listed");
            check(named(view, "layout-search").activeFocus, "Search takes focus on open");
            phase = 1;
        } else if (phase === 1) {
            // hyprctl stub reports the unprefixed name for a lua layout
            check(view.currentLayout === "grid", "Current layout read from hyprctl, got '" + view.currentLayout + "'");
            const grid = named(view, "layout-lua:grid");
            check(grid.highlighted && grid.text === "Grid · Active layout", "Active layout is marked: " + grid.text);
            check(!named(view, "layout-dwindle").highlighted, "Other layouts are not marked");
            for (const key of [Qt.Key_S, Qt.Key_P, Qt.Key_I]) input.keyClick(key, Qt.NoModifier, 0);
            check(view.filteredLayouts.length === 1 && view.filteredLayouts[0].id === "lua:spiral", "Search filters by name");
            input.keyClick(Qt.Key_Enter, Qt.NoModifier, 0);
            check(IslandState.mode === IslandState.defaultMode, "Choosing a layout closes the panel");
            phase = 2;
        } else if (phase === 2) {
            const log = Quickshell.env("LAYOUT_LOG");
            const file = Qt.createQmlObject('import Quickshell.Io; FileView { path: "' + log + '"; blockLoading: true }', root);
            check(file.text().trim() === "--layout lua:spiral", "Script got the layout id, got '" + file.text().trim() + "'");
            console.log("PASS: layout panel lists layouts, marks the active one, filters, and runs menu-layout with the layout id");
            Qt.quit();
        }
    }

    Timer {
        interval: 300
        running: true
        repeat: true
        onTriggered: {
            try { root.step(); }
            catch (error) { console.error("FAIL: " + error); Qt.quit(); }
        }
    }
}
