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

                // The badge's star favourites a card without applying it; the header star moves favourites first.
                const cellAt = n => cells().find(cell => cell.index === n);
                const starAt = n => root.allNamed(cellAt(n), "wallpaper-favorite-button", [])[0];
                const clickItem = item => {
                    const spot = item.mapToItem(null, item.width / 2, item.height / 2);
                    mouseClick(test, spot.x, spot.y);
                };
                const settle = () => tryVerify(() => !ThemeService.busy && ThemeService.pending.length === 0 && WallpaperService.pendingFavorites === null, 8000, "writes finish");
                const order = () => cells().sort((x, y) => x.index - y.index).map(cell => cell.path);
                const expectOrder = (expected, message) => {
                    for (let waited = 0; waited < 4000 && order().join("\n") !== expected.join("\n"); waited += 50) wait(50);
                    if (order().join("\n") !== expected.join("\n"))
                        console.log("ORDER MISMATCH " + message + " got=" + JSON.stringify(order().map(p => p.split("/").pop())) + " want=" + JSON.stringify(expected.map(p => p.split("/").pop())));
                    verify(order().join("\n") === expected.join("\n"), message);
                };
                const natural = order();
                verify(natural.length >= 4, "enough cards for the sort check");
                verify(starAt(0), "each card has a favorite button");
                clickItem(starAt(2));
                tryVerify(() => WallpaperService.isFavorite(natural[2]), 6000, "star saves the favorite");
                settle();
                compare(ThemeService.wallpaper, applied);
                tryVerify(() => (ThemeService.settings.wallpaperFavorites || []).includes(natural[2]), 6000, "favorite is saved");
                expectOrder(natural, "list order");

                const favoritesToggle = root.named(island, "panel-favorites-toggle");
                verify(favoritesToggle && favoritesToggle.visible, "header shows the favorites star");
                // Favorites-only lists just the starred cards; unstarring the last one empties the list.
                clickItem(favoritesToggle);
                expectOrder([natural[2]], "favorites only");
                settle();
                clickItem(starAt(0));
                tryVerify(() => !WallpaperService.isFavorite(natural[2]), 6000, "unstar inside the filter");
                expectOrder([], "empty favorites list");
                settle();
                clickItem(favoritesToggle);
                expectOrder(natural, "all wallpapers return");
                settle();

                // The favorites limit refuses another star once reached and says why; removing still works.
                ThemeService.setSetting("wallpaperFavoritesLimit", 5);
                tryVerify(() => WallpaperService.favoritesLimit === 5, 6000, "limit saved");
                settle();
                const filler = Array.from({length: 5}, (_, n) => "/tmp/not-a-real-wallpaper-" + n + ".png");
                ThemeService.setSetting("wallpaperFavorites", JSON.stringify(filler));
                tryVerify(() => WallpaperService.favorites.length === 5, 6000, "filler favorites saved");
                settle();
                clickItem(starAt(1));
                tryVerify(() => WallpaperService.favoritesNotice.length > 0, 2000, "limit notice appears");
                verify(!WallpaperService.isFavorite(natural[1]), "refused star is not saved");
                compare(WallpaperService.favorites.length, 5);
                // The notice also lengthens the status line; later steps measure the plain panel.
                WallpaperService.favoritesNotice = "";
                WallpaperService.toggleFavorite(filler[0]);
                tryVerify(() => WallpaperService.favorites.length === 4, 6000, "removing works at the limit");
                settle();
                ThemeService.setSetting("wallpaperFavorites", "[]");
                ThemeService.setSetting("wallpaperFavoritesLimit", 10);
                settle();
                tryVerify(() => WallpaperService.favorites.length === 0 && WallpaperService.favoritesLimit === 10, 6000, "limit test cleaned up");

                // The sort menu orders by name or by modification time (the shell test sets distinct times).
                const named = n => natural.find(path => path.endsWith("/" + n));
                const addedAsc = ["d3.png", "d5.png", "d4.png", "d1.png", "My Pic.png", "Linked.png"].map(named);
                const sortToggle = root.named(island, "panel-sort-toggle");
                verify(sortToggle && sortToggle.visible, "header shows the sort button");
                const pickSort = mode => {
                    clickItem(sortToggle);
                    tryVerify(() => root.named(island, "wallpaper-sort-menu").visible, 2000, "sort menu opens");
                    clickItem(root.named(island, "wallpaper-sort-" + mode));
                    tryVerify(() => !root.named(island, "wallpaper-sort-menu").visible, 2000, "sort menu closes");
                    settle();
                };
                pickSort("name-desc");
                expectOrder(natural.slice().reverse(), "name descending");
                pickSort("added-asc");
                expectOrder(addedAsc, "oldest first");
                pickSort("added-desc");
                expectOrder(addedAsc.slice().reverse(), "newest first");
                tryVerify(() => ThemeService.settings.wallpaperSort === "added-desc", 6000, "sort is saved");
                // Clicking elsewhere closes the menu without changing the order.
                clickItem(sortToggle);
                tryVerify(() => root.named(island, "wallpaper-sort-menu").visible, 2000, "menu opens again");
                keyClick(Qt.Key_Escape);
                tryVerify(() => !root.named(island, "wallpaper-sort-menu").visible, 2000, "Escape closes the menu");
                compare(IslandState.mode, mode);
                pickSort("name-asc");
                expectOrder(natural, "name ascending");

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

                // The editor fits inside its card, so the border is never clipped by the grid.
                rightClick(cells()[0]);
                tryVerify(() => { field = root.shownField(island); return !!field && field.visible && field.focus; }, 2000, "editor opens for the layout check");
                const cell = cells()[0];
                const bottom = field.mapToItem(cell, 0, field.height).y;
                verify(bottom <= cell.height - 1, "editor border stays inside the card: " + bottom + " vs " + cell.height);
                wait(100); // the header row relays out once the check appears
                const check = root.named(island, "panel-edit-confirm");
                const trash = root.named(island, "panel-delete-toggle");
                verify(check && check.visible, "header check shows while editing");
                verify(!trash.enabled, "trash is blocked while editing");
                // Clicking the trash neither enters delete mode nor saves anything; it only dismisses the edit.
                let point = trash.mapToItem(null, trash.width / 2, trash.height / 2);
                mouseClick(test, point.x, point.y);
                tryVerify(() => !field.visible, 2000, "clicking the header dismisses the editor");
                verify(trash.enabled, "trash works again");
                verify(!check.visible, "check hides with the editor");
                verify(listed(original), "dismissing never renames");

                // Clicking empty panel background dismisses without saving.
                rightClick(cells()[0]);
                tryVerify(() => { field = root.shownField(island); return !!field && field.visible && field.focus; }, 2000, "editor opens for the background check");
                keyClick(Qt.Key_Z);
                const header = root.named(island, "panel-title");
                point = header.mapToItem(null, Math.min(header.width - 4, header.contentWidth + 60), header.height / 2); // empty header space right of the title
                mouseClick(test, point.x, point.y);
                tryVerify(() => !field.visible, 2000, "background click dismisses the editor");
                verify(listed(original), "background click never renames");
                compare(IslandState.mode, mode);

                // The panel's own padding and the strip below the cards count as background too.
                for (const spot of ["margin", "below"]) {
                    rightClick(cells()[0]);
                    tryVerify(() => { field = root.shownField(island); return !!field && field.visible && field.focus; }, 2000, "editor opens for the " + spot + " click");
                    const card = cells()[0];
                    point = spot === "margin" ? card.mapToItem(null, -14, card.height / 2) : card.mapToItem(null, card.width / 2, card.height * 3 + 10); // below the default 3-row grid, inside the panel padding
                    mouseClick(test, point.x, point.y);
                    tryVerify(() => !field.visible, 2000, spot + " click dismisses the editor");
                    verify(listed(original), spot + " click never renames");
                }

                // Clicking inside the editor keeps it open.
                rightClick(cells()[0]);
                tryVerify(() => { field = root.shownField(island); return !!field && field.visible && field.focus; }, 2000, "editor opens for the inside click");
                point = field.mapToItem(null, field.width / 2, field.height / 2);
                mouseClick(test, point.x, point.y);
                wait(200);
                verify(field.visible, "click inside the editor keeps it open");
                keyClick(Qt.Key_Escape);
                tryVerify(() => !field.visible, 2000, "Escape still cancels");

                // The header check saves like Enter.
                rightClick(cells()[0]);
                tryVerify(() => { field = root.shownField(island); return !!field && field.visible && field.focus; }, 2000, "editor opens for the check save");
                keyClick(Qt.Key_A, Qt.ControlModifier);
                for (const letter of "zz viacheck") keyClick(letter);
                const saveButton = root.named(island, "panel-edit-confirm");
                point = saveButton.mapToItem(null, saveButton.width / 2, saveButton.height / 2);
                mouseClick(test, point.x, point.y);
                const viaCheck = "zz viacheck" + original.match(/\.[^.]+$/)[0];
                tryVerify(() => listed(viaCheck), 8000, "check saved the rename");
                verify(!listed(original), "old name gone after the check");
                tryVerify(() => !root.shownField(island), 2000, "editor closes after the check");
                // Rename it back so the Enter path below starts from the original name.
                rightClick(cells()[0]);
                tryVerify(() => { field = root.shownField(island); return !!field && field.visible && field.focus; }, 2000, "editor opens for the restore");
                keyClick(Qt.Key_A, Qt.ControlModifier);
                for (const letter of original.replace(/\.[^.]+$/, "")) keyClick(letter);
                keyClick(Qt.Key_Return);
                tryVerify(() => listed(original), 8000, "original name restored");

                // Enter renames, keeps the extension and never applies the wallpaper.
                rightClick(cells()[0]);
                tryVerify(() => { field = root.shownField(island); return !!field && field.visible && field.focus; }, 2000, "editor reopens");
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
                // Lowering the limit under the current favorites is refused with a drawer notice; once enough
                // are removed the same change goes through.
                const six = Array.from({length: 6}, (_, n) => "/tmp/not-a-real-wallpaper-" + n + ".png");
                ThemeService.setSetting("wallpaperFavorites", JSON.stringify(six));
                tryVerify(() => WallpaperService.favorites.length === 6, 6000, "six favorites saved");
                settle();
                IslandState.settingsSection = "wallpaperAnimation";
                IslandController.setMode(IslandState.settingsSectionMode, "HDMI-A-1");
                tryVerify(() => !!root.named(island, "setting-slider-wallpaperFavoritesLimit"), 5000, "limit slider shown");
                const limitSlider = root.named(island, "setting-slider-wallpaperFavoritesLimit");
                const limitSetting = limitSlider.parent;
                compare(limitSlider.value, 10);
                limitSlider.value = 5;
                limitSetting.dirty = true;
                limitSetting.saveValue();
                tryVerify(() => StatusManager.visible && StatusManager.mode === "notice", 2000, "notice slides down");
                compare(StatusManager.title, "Remove 1 favorite to lower the limit to 5");
                tryCompare(limitSlider, "value", 10, 2000);
                wait(300);
                compare(ThemeService.settings.wallpaperFavoritesLimit, 10);
                ThemeService.setSetting("wallpaperFavorites", JSON.stringify(six.slice(0, 5)));
                tryVerify(() => WallpaperService.favorites.length === 5, 6000, "one favorite removed");
                settle();
                limitSlider.value = 5;
                limitSetting.dirty = true;
                limitSetting.saveValue();
                tryVerify(() => ThemeService.settings.wallpaperFavoritesLimit === 5, 6000, "limit now applies");
                settle();
                ThemeService.setSetting("wallpaperFavoritesLimit", 10);
                ThemeService.setSetting("wallpaperFavorites", "[]");
                settle();
                console.log("PASS: wallpaper rename editor");
            }
            function cleanupTestCase() { quitTimer.start(); }
        }
    }
}
