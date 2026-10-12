import QtQuick
import QtTest
import Quickshell
import "../../core"
import "../../island"
import "../../modules/chromack"
import "../../services"

ShellRoot {
    id: root

    property int phase: 0
    property int elapsed: 0
    property int recentBefore: 0
    property bool stepping: false
    readonly property var view: viewLoader.item
    readonly property var panel: view ? named(view, "chromack-panel-loader").item : null

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

    function key(code, modifiers) {
        check(input.keyClick(code, modifiers ?? Qt.NoModifier, 0), "Deliver key " + code);
    }

    function type(text) {
        for (const ch of text)
            key(ch === "#" ? Qt.Key_NumberSign : /[0-9]/.test(ch) ? Qt.Key_0 + Number(ch) : Qt.Key_A + "abcdef".indexOf(ch));
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
            source: "../../views/ChromackView.qml"
        }
    }

    Timer {
        interval: 40
        repeat: true
        running: true
        onTriggered: {
            // Synthetic input can spin the event loop; never re-enter a phase.
            if (root.stepping)
                return;
            root.elapsed += interval;
            root.stepping = true;
            try {
                if (root.elapsed > 8000)
                    throw new Error("Phase " + root.phase + " timed out (panel " + !!root.panel + ", hex " + ChromackService.data?.hex
                        + ", mode " + IslandState.mode + ", error '" + ChromackService.errorMessage + "')");
                if (root.phase === 0) {
                    if (!ThemeService.ready || !root.panel || !root.named(root.panel, "chromack-material-47"))
                        return;
                    const hex = root.named(root.panel, "chromack-hex");
                    root.check(root.view.implicitWidth === 900 && root.view.implicitHeight === 620, "Panel reports its size");
                    root.check(!root.named(root.view, "chromack-unavailable").parent.visible, "Plugin loads without the fallback");
                    root.check(ChromackService.data.hex === "#336699", "Active color comes from the shared cache: " + ChromackService.data.hex);
                    root.check(ChromackService.data.subtitle === "Material 01 · #336699", "Subtitle names the slot: " + ChromackService.data.subtitle);
                    root.check(hex.activeFocus, "Hex input has focus on open");
                    root.check(hex.text === "#336699", "Hex input shows the active color");
                    hex.selectAll();
                    root.type("#ff0000");
                    root.next();
                } else if (root.phase === 1) {
                    const hex = root.named(root.panel, "chromack-hex");
                    root.check(hex.text === "#ff0000", "Typing edits the hex input: " + hex.text);
                    root.key(Qt.Key_Return);
                    root.check(ChromackService.data.hex === "#ff0000", "Enter generates from the typed color: " + ChromackService.data.hex);
                    root.check(ChromackService.data.status.indexOf("Generated 24-base palette") === 0, "Generate reports its status");
                    root.check(root.named(root.panel, "chromack-rgba").text === "rgba(255, 0, 0, 1)", "RGBA follows the active color");
                    root.click(root.named(root.panel, "chromack-material-5"));
                    root.check(ChromackService.data.selected === 5, "Material swatches select a slot");
                    root.check(hex.text === ChromackService.data.hex, "Hex input follows the selected slot");
                    root.key(Qt.Key_2, Qt.ControlModifier);
                    root.check(ChromackService.tab === 1, "Ctrl+2 opens Palette");
                    root.next();
                } else if (root.phase === 2) {
                    if (!root.named(root.panel, "chromack-page").item)
                        return;
                    root.check(ChromackService.data.palette.length === 26, "Palette has foreground, background and 24 colors");
                    root.recentBefore = ChromackService.data.recent.length;
                    root.click(root.named(root.panel, "chromack-preview"));
                    root.key(Qt.Key_3, Qt.ControlModifier);
                    root.check(ChromackService.tab === 2, "Ctrl+3 opens Theory");
                    root.next();
                } else if (root.phase === 3) {
                    if (!root.named(root.panel, "chromack-wheel") || ChromackService.data.recent.length !== root.recentBefore + 1)
                        return;
                    root.check(ChromackService.data.theory.length === 6 && ChromackService.data.wheel.length === 24, "Theory lists six schemes and a 24-segment wheel");
                    root.key(Qt.Key_S, Qt.ControlModifier);
                    root.check(ChromackService.savePrompt, "Ctrl+S opens the save prompt");
                    root.check(root.named(root.panel, "chromack-save-name").activeFocus, "Save prompt focuses its name field");
                    root.key(Qt.Key_Escape);
                    root.check(!ChromackService.savePrompt, "Escape cancels the save prompt first");
                    root.click(root.named(root.panel, "chromack-tab-shades"));
                    root.check(ChromackService.tab === 0, "Tab chips select pages");
                    root.key(Qt.Key_S, Qt.ControlModifier);
                    root.next();
                } else if (root.phase === 4) {
                    const prompt = root.named(root.panel, "chromack-save-prompt");
                    if (prompt.height < 49)
                        return;
                    root.named(root.panel, "chromack-save-name").text = "Island Test";
                    root.click(root.named(root.panel, "chromack-save-confirm"));
                    root.next();
                } else if (root.phase === 5) {
                    if (ChromackService.savePrompt || ChromackService.data.status.indexOf("Saved palette to") !== 0)
                        return;
                    IslandController.openChromack();
                    root.check(IslandState.mode === IslandState.chromackMode, "Chromack mode opens");
                    root.key(Qt.Key_P, Qt.ControlModifier);
                    root.check(ChromackService.picking && IslandState.mode === IslandState.defaultMode,
                        "Eyedropper collapses the panel while picking");
                    root.next();
                } else if (root.phase === 6) {
                    if (ChromackService.picking || IslandState.mode !== IslandState.chromackMode)
                        return;
                    root.check(ChromackService.data.hex === "#12ab34", "Eyedropper sets the active slot: " + ChromackService.data.hex);
                    root.check(ChromackService.data.selected === 5, "Eyedropper keeps the selected slot");
                    root.check(ChromackService.data.recent[0].hex === "#12ab34", "Picked color leads recents");
                    viewLoader.active = false;
                    root.next();
                } else if (root.phase === 7) {
                    console.log("PASS: chromack panel");
                    Qt.quit();
                }
            } catch (error) {
                console.log("FAIL: " + error.message);
                Qt.exit(1);
            } finally {
                root.stepping = false;
            }
        }
    }
}
