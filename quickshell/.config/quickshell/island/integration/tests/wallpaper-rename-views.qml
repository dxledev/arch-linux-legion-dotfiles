import QtQuick
import QtTest
import Quickshell
import "../../island"
import "../../core"
import "../../services"

// Right-click rename inside a full Island: the editor opens on the clicked card, Escape cancels
// without closing the island, and Enter renames through the controller without applying the wallpaper.
ShellRoot {
    id: root

    function named(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const found = named(child, name);
            if (found) return found;
        }
        return null;
    }
    // The grid and the (hidden) carousel both instantiate cards; only the shown editor counts.
    function shownField(item) {
        return allNamed(item, "wallpaper-rename-field", []).find(field => field.visible && field.width > 0) || null;
    }
    function allNamed(item, name, found) {
        if (!item) return found;
        if (item.objectName === name) found.push(item);
        for (const child of item.children) allNamed(child, name, found);
        return found;
    }

    Timer { id: quitTimer; interval: 100; onTriggered: Qt.quit() }

    FloatingWindow {
        id: window
        visible: true
        color: "transparent"
        implicitWidth: 900
        implicitHeight: 900
        Island { id: island; x: 100; y: 10; monitorName: "HDMI-A-1" }
        TestCase {
            id: test
            name: "wallpaper-rename"
            when: window.visible

            function cells() {
                return root.allNamed(island, "wallpaper-cell", []).filter(cell => cell.visible && cell.width > 0);
            }
            function listed(name) {
                for (let i = 0; i < WallpaperService.allWallpapers.count; i++)
                    if (WallpaperService.allWallpapers.get(i).path.split("/").pop() === name) return true;
                return false;
            }
            function anyFieldFocused() {
                return root.allNamed(island, "wallpaper-rename-field", []).some(field => field.activeFocus);
            }
            function rightClick(cell) {
                const point = cell.mapToItem(null, cell.width / 2, 40);
                mouseClick(test, point.x, point.y, Qt.RightButton);
            }

            function test_rename() {
                try { run(); } catch (error) { console.log("FAILED: " + error); throw error; }
            }
            function run() {
                ThemeService.settings = ThemeService.settings || ({});
                IslandController.setMode(IslandState.wallpaperSelectorMode, "HDMI-A-1");
                tryVerify(() => WallpaperService.allWallpapers.count >= 2, 8000, "wallpapers listed");
                tryVerify(() => cells().length >= 2, 4000, "cards shown");
                const mode = IslandState.mode;
                const applied = ThemeService.wallpaper;
                const first = WallpaperService.allWallpapers.get(0).path;
                const original = first.split("/").pop();

                // Right-click opens the editor on the stem, selected; the extension is shown beside it.
                rightClick(cells()[0]);
                let field = root.shownField(island);
                verify(field && field.visible, "editor opens");
                tryVerify(() => field.focus, 2000, "editor has focus");
                compare(field.text, original.replace(/\.[^.]+$/, ""));
                compare(field.suffix, original.match(/\.[^.]+$/)[0]);

                // Escape cancels the editor only.
                keyClick(Qt.Key_Escape);
                wait(300);
                tryVerify(() => !field.visible, 2000, "editor closes");
                compare(IslandState.mode, mode);
                verify(listed(original), "file untouched");
                verify(!anyFieldFocused(), "no hidden editor keeps the focus");
                // Keys go back to the list: Right moves the selection instead of editing hidden text.
                keyClick(Qt.Key_Right);
                verify(!anyFieldFocused(), "arrow keys do not reach a hidden editor");

                // Enter renames, keeps the extension and never applies the wallpaper.
                rightClick(cells()[0]);
                field = root.shownField(island);
                tryVerify(() => field && field.visible && field.focus, 2000, "editor reopens");
                keyClick(Qt.Key_A, Qt.ControlModifier);
                for (const letter of "zz renamed") keyClick(letter);
                keyClick(Qt.Key_Return);
                const renamed = "zz renamed" + original.match(/\.[^.]+$/)[0];
                tryVerify(() => listed(renamed), 8000, "renamed file listed");
                verify(!listed(original), "old name gone");
                compare(IslandState.mode, mode);
                verify(!anyFieldFocused(), "no editor keeps the focus after Enter");
                // With focus back on the list, Escape closes the island instead of being swallowed.
                keyClick(Qt.Key_Escape);
                tryVerify(() => IslandState.mode === IslandState.defaultMode, 3000, "Escape leaves the panel once the editor is gone");
                // The applied wallpaper is the renamed file only when that is the one that was renamed.
                const expected = applied === first ? first.slice(0, first.lastIndexOf("/") + 1) + renamed : applied;
                tryVerify(() => ThemeService.wallpaper === expected, 8000, "applied wallpaper follows: " + ThemeService.wallpaper + " vs " + expected);
                console.log("PASS: wallpaper rename editor");
            }
            function cleanupTestCase() { quitTimer.start(); }
        }
    }
}
