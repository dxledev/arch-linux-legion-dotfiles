import QtQuick
import QtTest
import Quickshell
import "../../views"
import "../../services"
import "../../core"
import "../../island"

ShellRoot {
    id: root

    property int phase: 0
    property int elapsed: 0
    readonly property var view: viewLoader.item

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }

    function named(item, objectName) {
        if (!item) return null;
        if (item.objectName === objectName) return item;
        for (const child of item.children ?? []) {
            const found = named(child, objectName);
            if (found) return found;
        }
        return null;
    }

    function next() {
        phase++;
        elapsed = 0;
    }

    TestEvent { id: input }

    FloatingWindow {
        visible: true
        implicitWidth: 760
        implicitHeight: 620

        Loader {
            id: viewLoader
            x: 30
            y: 20
            focus: true
            source: "../../views/KeybindsView.qml"
        }
    }

    Timer {
        interval: 40
        repeat: true
        running: true
        onTriggered: {
            root.elapsed += interval;
            try {
                const search = root.named(root.view, "keybind-search");
                const list = root.named(root.view, "keybind-list");
                if (root.elapsed > 8000)
                    throw new Error("Phase " + root.phase + " timed out (loading "
                        + KeybindService.loading + ", entries " + KeybindService.entries.length
                        + ", error '" + KeybindService.error + "')");

                if (root.phase === 0) {
                    if (KeybindService.loading || !search || !list || list.count !== 3) return;
                    root.check(KeybindService.error === "", "The fixture list loads without error");
                    root.check(root.view.visibleEntries[0].description === "Global Window Left",
                        "The global shortcut is rendered first");
                    root.check(root.view.visibleEntries[0].shortcut === "SUPER + H",
                        "The shortcut label is shown");
                    root.check(root.view.visibleEntries.some(entry => entry.description === "Panel"),
                        "The shell name is removed from the description");
                    search.text = "panel";
                    root.check(list.count === 1 && root.view.visibleEntries[0].id === "island-id",
                        "Search filters to the Island shortcut");
                    search.text = "global window";
                    root.check(list.count === 1 && root.view.visibleEntries[0].id === "global-id",
                        "Search matches the global description");
                    search.text = "";
                    IslandController.openKeybinds();
                    root.check(IslandState.mode === IslandState.keybindsMode,
                        "The Keybinds panel opens through its controller route");
                    search.forceActiveFocus();
                    root.check(input.keyClick(Qt.Key_Down, Qt.NoModifier, 0), "Move focus from search into the list");
                    root.check(list.activeFocus && list.currentIndex === 0,
                        "Down from search focuses the first shortcut");
                    root.check(input.keyClick(Qt.Key_Down, Qt.NoModifier, 0), "Move selection down");
                    root.check(list.currentIndex === 1, "Down selects the second shortcut");
                    root.check(input.keyClick(Qt.Key_Return, Qt.NoModifier, 0), "Activate the selected shortcut");
                    root.next();
                } else if (root.phase === 1) {
                    if (IslandState.mode !== IslandState.defaultMode || KeybindService.busy) return;
                    root.check(KeybindService.error === "", "Successful execution clears the service error");
                    search.text = "Failing Shortcut";
                    IslandController.openKeybinds();
                    root.check(list.count === 1 && root.view.visibleEntries[0].id === "failure-id",
                        "The failing fixture can be selected by search");
                    root.check(input.mouseClick(list, 40, 28, Qt.LeftButton, Qt.NoModifier, 0),
                        "Deliver pointer click to the failing shortcut");
                    root.next();
                } else if (root.phase === 2) {
                    if (KeybindService.busy || !root.view.displayError.includes("synthetic dispatch failure")) return;
                    root.check(IslandState.mode === IslandState.keybindsMode,
                        "A failed dispatch keeps the Keybinds panel open");
                    search.text = "";
                    root.check(input.mouseClick(list, 40, 28, Qt.LeftButton, Qt.NoModifier, 0),
                        "Deliver pointer click to the first shortcut");
                    root.next();
                } else if (root.phase === 3) {
                    if (IslandState.mode !== IslandState.defaultMode || KeybindService.busy) return;
                    console.log("PASS: keybinds search, descriptions, keyboard navigation, pointer execution, dispatch errors, and panel closure");
                    Qt.quit();
                }
            } catch (error) {
                console.error("FAIL: " + error.message);
                Qt.exit(1);
            }
        }
    }
}
