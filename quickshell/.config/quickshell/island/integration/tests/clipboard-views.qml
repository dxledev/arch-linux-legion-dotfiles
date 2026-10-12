import QtQuick
import QtTest
import Quickshell
import "../../core"
import "../../island"
import "../../modules/clipboard"
import "../../services"

ShellRoot {
    id: root

    property int phase: 0
    property int elapsed: 0
    readonly property var view: viewLoader.item
    readonly property var panel: view ? named(view, "clipboard-panel-loader").item : null

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }

    function named(item, objectName) {
        if (!item) return null;
        if (item.objectName === objectName) return item;
        for (const child of item.children) {
            const result = named(child, objectName);
            if (result) return result;
        }
        return null;
    }

    function click(item) {
        check(item, "Pointer target exists");
        check(input.mouseClick(item, item.width / 2, item.height / 2, Qt.LeftButton, Qt.NoModifier, 0),
              "Deliver pointer click");
    }

    function key(code) {
        check(input.keyClick(code, Qt.NoModifier, 0), "Deliver key " + code);
    }

    function previewTitle() {
        return named(panel, "clipboard-preview-title").text;
    }

    function next() { phase++; elapsed = 0; }

    TestEvent { id: input }

    FloatingWindow {
        visible: true
        implicitWidth: 960
        implicitHeight: 680

        Loader {
            id: viewLoader
            x: 30
            y: 30
            focus: true
            source: "../../views/ClipboardView.qml"
        }
    }

    Timer {
        interval: 40
        repeat: true
        running: true
        onTriggered: {
            root.elapsed += interval;
            try {
                const history = root.panel ? root.named(root.panel, "clipboard-history-list") : null;
                if (root.elapsed > 8000)
                    throw new Error("Phase " + root.phase + " timed out (panel " + !!root.panel + ", loading "
                        + ClipboardService.loading + ", history " + (history ? history.count : "none") + ", error '"
                        + ClipboardService.errorMessage + "')");
                if (root.phase === 0) {
                    if (!ThemeService.ready || !root.panel || ClipboardService.loading || !history || history.count !== 3)
                        return;
                    root.check(root.view.implicitWidth === 900 && root.view.implicitHeight === 620, "Panel reports its size");
                    root.check(!root.named(root.view, "clipboard-unavailable").parent.visible, "Plugin loads without the fallback");
                    root.check(root.previewTitle() === "https://example.com/page", "Newest entry is selected first: " + root.previewTitle());
                    root.check(root.named(root.panel, "clipboard-preview-open-link").visible, "Links offer Open link");
                    root.check(root.named(root.panel, "clipboard-search").activeFocus, "Search has focus on open");
                    root.key(Qt.Key_Down);
                    root.check(history.currentIndex === 1, "Down selects the next entry");
                    root.next();
                } else if (root.phase === 1) {
                    if (root.named(root.panel, "clipboard-preview-text").text.indexOf('\n  "name": "island"') === -1)
                        return;
                    root.check(!root.named(root.panel, "clipboard-preview-open-link").visible, "JSON hides Open link");
                    root.key(Qt.Key_Tab);
                    root.check(root.panel.activeFilter === "pinned", "Tab cycles to the Pinned filter");
                    root.check(root.named(root.panel, "clipboard-pinned-empty").visible, "Empty pinned list explains itself");
                    root.click(root.named(root.panel, "clipboard-filter-link"));
                    root.check(root.panel.activeFilter === "link", "Clicking a chip selects its filter");
                    root.next();
                } else if (root.phase === 2) {
                    if (history.count !== 1)
                        return;
                    root.check(root.previewTitle() === "https://example.com/page", "Links filter keeps only links");
                    root.click(root.named(root.panel, "clipboard-filter-all"));
                    root.named(root.panel, "clipboard-search").text = "hello";
                    root.next();
                } else if (root.phase === 3) {
                    if (history.count !== 1 || root.previewTitle() !== "hello clipboard world")
                        return;
                    root.click(root.named(history, "clipboard-row-pin"));
                    root.next();
                } else if (root.phase === 4) {
                    if (ClipboardService.controller.favoritesModel.count !== 1)
                        return;
                    root.click(root.named(root.panel, "clipboard-filter-pinned"));
                    root.check(root.named(root.panel, "clipboard-pinned-list").count === 1, "Pinned entry appears under Pinned");
                    root.click(root.named(root.panel, "clipboard-filter-all"));
                    root.named(root.panel, "clipboard-search").forceActiveFocus();
                    IslandController.openClipboard();
                    root.check(IslandState.mode === IslandState.clipboardMode, "Clipboard mode opens");
                    root.key(Qt.Key_Return);
                    root.next();
                } else if (root.phase === 5) {
                    if (IslandState.mode !== IslandState.defaultMode)
                        return;
                    root.panel.requestClear();
                    root.check(root.panel.confirmationOpen, "Clear asks for confirmation");
                    root.key(Qt.Key_Escape);
                    root.check(!root.panel.confirmationOpen, "Escape cancels the confirmation");
                    root.panel.requestClear();
                    root.next();
                } else if (root.phase === 6) {
                    if (root.named(root.panel, "clipboard-confirmation").opacity !== 1)
                        return;
                    root.check(root.named(root.panel, "clipboard-confirm-accept").activeFocus, "Confirm button takes focus");
                    root.click(root.named(root.panel, "clipboard-confirm-accept"));
                    root.next();
                } else if (root.phase === 7) {
                    if (root.panel.confirmationOpen || history.count !== 0)
                        return;
                    console.log("PASS: clipboard panel");
                    Qt.quit();
                }
            } catch (error) {
                console.log("FAIL: " + error.message);
                Qt.exit(1);
            }
        }
    }
}
