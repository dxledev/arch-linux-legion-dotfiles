import QtQuick
import QtTest
import Quickshell
import "../../core"
import "../../island"
import "../../services"

// Drives the real Browse Wallpapers panel against the real helper and a mock wallhaven API.
ShellRoot {
    id: root

    property int phase: 0
    property int elapsed: 0
    property bool stepping: false
    readonly property var panel: viewLoader.item
    readonly property var service: WallhavenService

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }

    function named(item, objectName) {
        if (!item) return null;
        if (item.objectName === objectName) return item;
        const kids = item.contentItem ? [item.contentItem, ...item.children] : item.children;
        for (const child of kids) {
            const result = named(child, objectName);
            if (result) return result;
        }
        return null;
    }

    // Scrolls the nearest Flickable so the target is inside its visible area before clicking.
    function reveal(item) {
        let flick = item.parent;
        while (flick && !(flick.contentItem && flick.contentY !== undefined && flick.interactive !== undefined && flick.contentHeight > flick.height)) flick = flick.parent;
        if (!flick) return;
        const top = item.mapToItem(flick.contentItem, 0, 0).y;
        if (top < flick.contentY + 8 || top + item.height > flick.contentY + flick.height - 8)
            flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, top - 60));
    }

    function click(item) {
        check(item, "Pointer target exists");
        reveal(item);
        check(input.mouseClick(item, item.width / 2, item.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Deliver pointer click");
    }

    function key(code, modifiers) {
        check(input.keyClick(code, modifiers ?? Qt.NoModifier, 0), "Deliver key " + code);
    }

    function type(text) {
        for (const letter of text) check(input.keyClickChar(letter, Qt.NoModifier, 0), "Deliver character " + letter);
    }

    function previewCount(mode) {
        let count = 0;
        for (const id in service.previews) if (id.startsWith(mode + ":")) count++;
        return count;
    }

    function next() { phase++; elapsed = 0; }

    TestEvent { id: input }

    FloatingWindow {
        visible: true
        implicitWidth: 1160
        implicitHeight: 800
        Loader {
            id: viewLoader
            x: 30
            y: 30
            focus: true
            source: "../../views/WallhavenView.qml"
        }
    }

    Timer {
        interval: 50
        repeat: true
        running: true
        onTriggered: {
            if (root.stepping) return;
            root.elapsed += interval;
            root.stepping = true;
            try {
                if (root.elapsed > 25000)
                    throw new Error("Phase " + root.phase + " timed out (results " + service.results.count + ", selected '" + service.selectedId
                        + "', prepared '" + service.preparedPath + "', previews " + Object.keys(service.previews).length
                        + ", status '" + service.workStatus + "', error '" + service.error + service.workError + service.prepareError + "')");
                const view = root.panel;
                if (root.phase === 0) {
                    if (!view || !ThemeService.ready || !service.configReady || service.results.count !== 24) return;
                    IslandController.openWallhaven();
                    root.check(IslandState.mode === IslandState.wallhavenMode, "Wallhaven mode opens");
                    const grid = root.named(view, "wallhaven-grid");
                    root.check(grid && grid.count === 24, "Search results fill the grid");
                    root.check(service.pageSize === 0 && service.effectivePageSize === 24
                        && JSON.stringify(service.pageSizeOptions) === "[24,12,8,6,4]", "Per-page options divide wallhaven's page: " + JSON.stringify(service.pageSizeOptions));
                    root.check(service.filters.categories === "101" && service.filters.sorting === "favorites",
                        "First run starts from Aether's Wallhaven defaults: " + JSON.stringify(service.filters));
                    root.check(service.meta.total === 60 && service.hasMore, "Pagination metadata arrives");
                    root.check(root.named(view, "panel-title").text === "Browse Wallpapers", "Panel is titled Browse Wallpapers");
                    root.check(service.schemeGroups.length === 5 && service.schemeGroups[0].schemes[0].id === "pastel",
                        "Pastel leads the first scheme group: " + JSON.stringify(service.schemeGroups.map(g => g.key)));
                    root.check(service.schemeGroups[service.schemeGroups.length - 1].schemes.length === 9, "Island's Material variants are offered");
                    root.next();
                } else if (root.phase === 1) {
                    root.click(root.named(view, "wallhaven-sort-toplist"));
                    root.check(service.filters.sorting === "toplist", "Sort chips change the filter");
                    root.next();
                } else if (root.phase === 2) {
                    // The filter change re-searches after a short debounce.
                    if (service.activeFilters.sorting !== "toplist" || service.busy) return;
                    root.check(service.results.count === 24, "Re-search keeps the page of results");
                    root.click(root.named(view, "wallhaven-filters-toggle"));
                    root.next();
                } else if (root.phase === 3) {
                    const drawer = root.named(view, "wallhaven-filters");
                    root.check(drawer.expanded, "Filters drawer opens");
                    if (drawer.height < 300) return;
                    root.click(root.named(view, "wallhaven-chip-16:9"));
                    root.check(service.filters.ratios.indexOf("16x9") >= 0, "Ratio chips filter by aspect ratio");
                    root.click(root.named(view, "wallhaven-chip-Year"));
                    root.check(service.filters.topRange === "1y", "Top range applies to the toplist");
                    root.key(Qt.Key_Escape);
                    root.check(!drawer.expanded, "Escape closes the drawer before the panel");
                    root.next();
                } else if (root.phase === 4) {
                    if (service.busy || service.activeFilters.ratios.indexOf("16x9") < 0 || service.activeFilters.topRange !== "1y") return;
                    const card = root.named(view, "wallhaven-card-abc123");
                    root.check(card, "Result card renders");
                    root.click(card);
                    root.check(service.selectedId === "abc123", "Clicking a card opens its details");
                    root.next();
                } else if (root.phase === 5) {
                    if (!service.preparedPath || !service.detail || root.previewCount("dark") < 29) return;
                    root.check(service.preparedPath.indexOf("/images/wallhaven-abc123.png") > 0, "Full image is cached for palette generation");
                    root.check(service.detail.tags[0].name === "sky" && service.detail.uploader === "someone", "Tags and uploader load");
                    root.check(service.selectedPalette && service.selectedPalette.style === "wh-pastel", "Pastel is the default palette");
                    root.check(service.selectedPalette.terminal.length === 16, "Preview carries all sixteen terminal colors");
                    root.check(root.named(view, "wallhaven-detail"), "Detail pane is shown");
                    // The staged download can be renamed before it is saved; Escape resets, Enter keeps the name.
                    const nameField = root.named(view, "wallhaven-name-field");
                    root.check(nameField && nameField.visible && nameField.text === "wallhaven-abc123" && nameField.suffix === ".png",
                        "The staged name starts as wallhaven-ID: '" + (nameField && nameField.text) + "' '" + (nameField && nameField.suffix) + "'");
                    root.click(nameField);
                    root.check(nameField.activeFocus, "The name field takes focus");
                    root.key(Qt.Key_A, Qt.ControlModifier);
                    root.type("Scratch");
                    root.check(service.stagedName === "Scratch", "Typing edits the staged name: " + service.stagedName);
                    root.key(Qt.Key_Escape);
                    root.check(service.stagedName === "wallhaven-abc123" && service.selectedId === "abc123" && nameField.text === "wallhaven-abc123", "Escape resets the name and keeps the detail pane: '" + nameField.text + "'");
                    root.click(nameField);
                    root.key(Qt.Key_A, Qt.ControlModifier);
                    root.type("Sky Pic");
                    root.key(Qt.Key_Return);
                    root.check(service.stagedName === "Sky Pic" && service.selectedId === "abc123", "Enter keeps the typed name");
                    root.click(root.named(view, "wallhaven-scheme-candy"));
                    root.check(service.selectedScheme === "candy" && service.selectedKind === "aether", "Island's own schemes can be chosen");
                    root.click(root.named(view, "wallhaven-mode-light"));
                    root.check(service.previewMode === "light", "Light mode can be previewed");
                    root.next();
                } else if (root.phase === 6) {
                    if (root.previewCount("light") < 29) return;
                    root.check(service.selectedPalette.mode === "light" && service.selectedPalette.scheme === "candy", "Light Candy palette is previewed");
                    root.click(root.named(view, "wallhaven-scheme-expressive"));
                    root.check(service.selectedKind === "material" && service.selectedPalette === null, "Material variants apply without a preview");
                    root.click(root.named(view, "wallhaven-scheme-pastel"));
                    root.click(root.named(view, "wallhaven-apply"));
                    root.check(service.working, "Apply starts working");
                    root.next();
                } else if (root.phase === 7) {
                    if (service.working || !service.workStatus) return;
                    root.check(service.workStatus === "Applied wallpaper and palette", "Apply finishes: '" + service.workStatus + "' " + service.workError);
                    root.check(service.results.get(0).installed === true, "The card shows it is now in the library");
                    root.next();
                } else if (root.phase === 8) {
                    // With the detail pane closed the whole 24-wallpaper page fits without scrolling.
                    service.closeDetail();
                    const wide = root.named(view, "wallhaven-grid");
                    if (wide.width < 1000) return;
                    console.log("wide grid " + wide.width + "x" + wide.height + " columns " + wide.columns + " cell " + wide.cellWidth + "x" + wide.cellHeight);
                    root.check(wide.pageFits && wide.columns >= 6, "A full page fits the grid: " + wide.columns + " columns");
                    root.check(wide.contentHeight <= wide.height + 0.01, "No row is cut off or hidden below the fold: " + wide.contentHeight + " > " + wide.height);
                    root.check(wide.cellHeight / wide.cellWidth >= 0.55, "Thumbnails keep a sensible aspect");
                    root.next();
                } else if (root.phase === 9) {
                    // Pagination replaces the grid page by page instead of scrolling for more.
                    const pager = root.named(view, "wallhaven-pager");
                    root.check(pager && pager.visible, "Pager shows when there is more than one page");
                    root.check(service.meta.page === 1 && root.named(view, "wallhaven-page-1").checked, "Page 1 is current");
                    root.check(root.named(view, "wallhaven-page-3") && !root.named(view, "wallhaven-page-4"), "Pager lists every page of a short result");
                    const grid = root.named(view, "wallhaven-grid");
                    console.log("grid " + grid.width + "x" + grid.height + " columns " + grid.columns + " cell " + grid.cellWidth + "x" + grid.cellHeight);
                    root.check(Math.abs(grid.cellHeight * grid.visibleRows - grid.height) < 0.01 || grid.pageFits, "Rows divide the grid height so none is cut off");
                    root.check(grid.contentHeight <= grid.height + 0.01 || grid.pageRows * grid.cellHeight > grid.height,
                        "Whole rows only: " + grid.contentHeight + " in " + grid.height);
                    root.check(service.results.get(0).wid === "abc123" && service.results.get(23).wid === "p1i23", "Page 1 holds its own 24 wallpapers");
                    root.check(service.cacheHits === 0 && service.fetchCount >= 2, "Page 1 was fetched and page 2 prefetched: " + service.fetchCount);
                    root.click(root.named(view, "wallhaven-page-next"));
                    // Served from the prefetch: no spinner, the grid is already page 2.
                    root.check(!service.searching && service.meta.page === 2 && service.cacheHits === 1, "Next comes from the prefetched page instantly");
                    root.next();
                } else if (root.phase === 10) {
                    if (service.busy) return;
                    root.check(service.meta.page === 2 && service.requestedPage === 2, "Next page loads page 2");
                    root.check(service.results.count === 24 && service.results.get(0).wid === "p2i00" && service.results.get(23).wid === "p2i23",
                        "Page 2 replaced the grid instead of extending it: " + service.results.get(0).wid);
                    root.check(root.named(view, "wallhaven-grid").contentY === 0, "A new page starts at the top");
                    root.check(root.named(view, "wallhaven-page-2").checked, "Page 2 becomes current");
                    root.click(root.named(view, "wallhaven-page-3"));
                    root.next();
                } else if (root.phase === 11) {
                    if (service.busy) return;
                    root.check(service.meta.page === 3 && !service.hasMore, "Page chips jump to a page");
                    root.check(!root.named(view, "wallhaven-page-next").enabled, "Next is disabled on the last page");
                    root.next();
                } else if (root.phase === 12) {
                    // Smaller pages are slices of the fetched page, with a bigger grid in the same panel.
                    const grid = root.named(view, "wallhaven-grid");
                    const cardWidth24 = grid.cellWidth;
                    const fetches = service.fetchCount;
                    const sizes = root.named(view, "wallhaven-page-sizes");
                    const sizeChips = [12, 8, 6, 4].map(n => root.named(view, "wallhaven-pagesize-" + n));
                    root.check(sizes && sizeChips.every(chip => chip), "Per-page chips are offered");
                    const sortRow = root.named(view, "wallhaven-sort-relevance").parent;
                    root.check(sizes.x >= sortRow.x + sortRow.width, "Per-page chips do not overlap the sort chips");
                    root.click(sizeChips[0]);
                    root.check(service.pageSize === 12 && service.results.count === 12 && service.fetchCount === fetches,
                        "Choosing 12 slices the loaded page without a request: " + service.results.count);
                    root.check(service.meta.lastPage === 5 && service.meta.page === 5 && service.results.get(0).wid === "p3i00",
                        "Page numbers follow the smaller size: " + JSON.stringify(service.meta) + " " + service.results.get(0).wid);
                    root.next();
                } else if (root.phase === 13) {
                    // (A tick later, so the pager has laid out its new page numbers.)
                    const fetches = service.fetchCount;
                    root.click(root.named(view, "wallhaven-page-prev"));
                    root.check(service.meta.page === 4 && service.results.get(0).wid === "p2i12" && service.fetchCount === fetches
                        && !service.searching, "The previous slice comes from the page cache: " + service.results.get(0).wid + " " + JSON.stringify(service.meta));
                    root.click(root.named(view, "wallhaven-pagesize-4"));
                    root.check(service.results.count === 4 && root.named(view, "wallhaven-grid").count === 4, "Choosing 4 shows four wallpapers");
                    root.next();
                } else if (root.phase === 14) {
                    const grid = root.named(view, "wallhaven-grid");
                    console.log("4-up grid " + grid.width + "x" + grid.height + " columns " + grid.columns + " cell " + grid.cellWidth + "x" + grid.cellHeight);
                    root.check(grid.cellWidth > 300 && grid.cellHeight > 150, "Four results get large thumbnails: " + grid.cellWidth + "x" + grid.cellHeight);
                    root.check(grid.pageFits && grid.contentHeight <= grid.height + 0.01, "Four results still fit without scrolling");
                    root.check(grid.cellWidth * grid.columns <= grid.parent.width + 0.01, "The grid stays inside the panel");
                    root.check(root.panel.width === 1100 && root.panel.height === 740, "The panel keeps its size");
                    // The detail pane narrows the grid; the bigger cells still fit.
                    service.select(service.rowItem(0));
                    root.next();
                } else if (root.phase === 15) {
                    const grid = root.named(view, "wallhaven-grid");
                    if (grid.parent.width > 700) return;
                    root.check(grid.pageFits && grid.cellWidth * grid.columns <= grid.parent.width + 0.01 && grid.cellHeight > 100,
                        "Large thumbnails also fit beside the detail pane: " + grid.columns + " " + grid.cellWidth + "x" + grid.cellHeight);
                    service.closeDetail();
                    root.next();
                } else if (root.phase === 16) {
                    // Clicking the wallhaven.cc source line switches to the Dynamic library.
                    const subtitle = root.named(view, "panel-subtitle");
                    root.check(subtitle && subtitle.text.startsWith("wallhaven.cc"), "The source line names wallhaven.cc: " + (subtitle && subtitle.text));
                    root.click(subtitle);
                    root.check(service.libraryView && service.libraryLoading, "Clicking wallhaven.cc opens the Dynamic library");
                    root.next();
                } else if (root.phase === 17) {
                    if (service.libraryLoading) return;
                    const names = []
                    for (let i = 0; i < service.results.count; i++) names.push(service.results.get(i).name);
                    root.check(JSON.stringify(names) === '["my-photo.png","other.png","Sky Pic.png"]', "Library lists the Dynamic folder: " + JSON.stringify(names));
                    root.check(root.named(view, "wallhaven-search") === null || !root.named(view, "wallhaven-search").visible, "Wallhaven search is hidden in the library");
                    root.check(root.named(view, "panel-subtitle").text.startsWith("Dynamic library"), "The source line names the library");
                    const row = service.results.get(0);
                    root.check(row.library === true && row.thumb.startsWith("file://") && row.wid === row.path, "Library cards carry local files");
                    root.click(root.named(view, "wallhaven-card-" + row.wid));
                    root.check(service.selectedId === row.wid && service.preparedPath === row.path, "Selecting a library wallpaper needs no download");
                    root.next();
                } else if (root.phase === 18) {
                    if (root.previewCount("light") < 29 || service.storedPalettes.length === 0) return;
                    root.check(service.storedPalettes[0].style === "wh-candy", "Stored palettes of that wallpaper load: " + JSON.stringify(service.storedPalettes));
                    root.check(service.selectedPalette && service.selectedPalette.style === "wh-pastel", "Library wallpapers preview palettes from the file");
                    root.check(root.named(view, "wallhaven-apply").text === "Add palette + apply", "Apply reads Add palette + apply");
                    root.check(root.named(view, "wallhaven-download") && !root.named(view, "wallhaven-download").visible, "Library items have no Save button");
                    root.click(root.named(view, "wallhaven-apply"));
                    root.check(service.working, "Adding a palette starts working");
                    root.next();
                } else if (root.phase === 19) {
                    if (service.working || !service.workStatus) return;
                    root.check(service.workStatus === "Applied wallpaper and palette", "Library apply finishes: '" + service.workStatus + "' " + service.workError);
                    root.click(root.named(view, "panel-subtitle"));
                    root.check(!service.libraryView, "Clicking the library line returns to wallhaven.cc");
                    root.next();
                } else if (root.phase === 20) {
                    if (service.busy || service.results.count !== 4 || service.results.get(0).library) return;
                    root.check(!service.libraryView && service.selectedId === "", "Wallhaven results return and the library selection is gone");
                    service.select(service.rowItem(0));
                    root.next();
                } else if (root.phase === 21) {
                    if (service.working || root.elapsed < 1500) return;  // lets the debounced settings save land
                    root.check(service.effectivePageSize === 4, "The chosen size persists while browsing");
                    root.key(Qt.Key_Escape);
                    root.check(service.selectedId === "", "Escape closes the detail pane first");
                    root.key(Qt.Key_Escape);
                    root.check(IslandState.mode === IslandState.defaultMode, "Escape then closes the panel");
                    console.log("PASS: wallhaven panel");
                    Qt.quit();
                }
            } catch (error) {
                console.log("FAIL: " + error.message);
                Qt.quit();
            } finally {
                root.stepping = false;
            }
        }
    }
}
