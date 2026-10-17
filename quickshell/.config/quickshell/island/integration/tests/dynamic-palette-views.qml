import QtQuick
import Quickshell
import "../../views"
import "../../services"

// Settings -> Dynamic palette with an active generated palette and one foreign Aether snapshot.
ShellRoot {
    id: root
    property int phase: 0
    property int elapsed: 0

    function check(condition, message) { if (!condition) throw new Error(message); }
    function named(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        const kids = item.contentItem ? [item.contentItem, ...item.children] : item.children;
        for (const child of kids) {
            const found = named(child, name);
            if (found) return found;
        }
        return null;
    }
    function choose(combo, value) {
        const index = combo.model.indexOf(value);
        check(index >= 0, value + " is offered");
        combo.currentIndex = index;
        combo.activated(index);
    }
    function idle() { return !ThemeService.busy && ThemeService.pending.length === 0; }

    FloatingWindow {
        visible: true
        implicitWidth: 640
        implicitHeight: 560
        Loader { id: loader; source: "../../views/DynamicPaletteSettingsView.qml" }
    }

    Timer {
        interval: 50; repeat: true; running: true
        onTriggered: {
            root.elapsed += interval;
            try {
                if (root.elapsed > 15000) throw new Error("Phase " + root.phase + " timed out (palettes " + JSON.stringify(ThemeService.generatedPalettes) + ")");
                const view = loader.item;
                if (root.phase === 0) {
                    if (!view || !ThemeService.ready || ThemeService.generatedPalettes.length === 0 || !root.idle()) return;
                    const palette = root.named(view, "setting-choice-Palette");
                    const mode = root.named(view, "setting-choice-Color mode");
                    root.check(palette && mode, "Both choices render");
                    root.check(ThemeService.generatedPalettes.length === 2, "Foreign snapshots are dropped: " + JSON.stringify(ThemeService.generatedPalettes));
                    root.check(palette.model.indexOf("generated:wh-pastel") === 0, "Generated palettes lead the list");
                    root.check(palette.model.every(value => value.indexOf("generated:") !== 0 || value.indexOf("generated:wh-") === 0), "Only Wallhaven palettes are listed");
                    root.check(palette.model.indexOf("generated:other-style") < 0, "The foreign Aether style is hidden");
                    root.check(palette.model.indexOf("tonalspot") > 0 && palette.model.length === 10, "Material variants remain");
                    root.check(palette.displayText === "Pastel · Wallhaven", "Active generated palette is labelled: " + palette.displayText);
                    root.check(palette.currentIndex === 0, "Active generated palette is selected");
                    root.choose(mode, "light");
                    root.phase = 1; root.elapsed = 0;
                } else if (root.phase === 1) {
                    if (!root.idle()) return;
                    root.choose(root.named(view, "setting-choice-Palette"), "vibrant");
                    root.phase = 2; root.elapsed = 0;
                } else if (root.phase === 2) {
                    if (!root.idle()) return;
                    root.choose(root.named(view, "setting-choice-Palette"), "generated:wh-pastel");
                    root.phase = 3; root.elapsed = 0;
                } else if (root.phase === 3) {
                    if (!root.idle()) return;
                    const full = root.named(view, "full-palette-toggle");
                    root.check(full && full.text === "Full", "The Full toggle renders");
                    root.check(!full.checked, "Full starts off");
                    full.click();
                    root.phase = 4; root.elapsed = 0;
                } else if (root.phase === 4) {
                    if (!root.idle()) return;
                    console.log("PASS: dynamic palette view");
                    Qt.quit();
                }
            } catch (error) {
                console.log("FAIL: " + error.message);
                Qt.quit();
            }
        }
    }
}
