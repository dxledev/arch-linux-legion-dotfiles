import QtQuick
import "../components"
import "../core"
import "../island"
import "../services"
import "../styles"

FocusScope {
    id: root
    readonly property int cellWidth: 184
    readonly property int cellHeight: 128
    function clampInt(value, min, max, fallback) {
        if (value === undefined || value === null || value === "") return fallback;
        const number = Math.round(Number(value));
        if (!isFinite(number)) return fallback;
        return Math.max(min, Math.min(max, number));
    }
    function setting(name) {
        return ThemeService.settings ? ThemeService.settings[name] : undefined;
    }
    readonly property int rows: clampInt(setting("wallpaperRows"), 1, 5, 3)
    readonly property int columns: clampInt(setting("wallpaperColumns"), 2, 5, 3)
    readonly property bool horizontal: setting("wallpaperScrollDirection") === "horizontal"
    readonly property bool infiniteScroll: setting("wallpaperInfiniteScroll") !== false
    readonly property int itemCount: filteredWallpapers.model.count
    // Single-row layouts can wrap; the carousel needs its visible slots plus a buffer slot on each
    // side, since PathView respaces items when count < pathItemCount.
    readonly property bool wrapping: infiniteScroll && rows === 1 && itemCount >= columns + 2
    // Horizontal mode moves by a whole column on left/right; vertical mode moves by a column of cells.
    readonly property int horizontalStep: horizontal ? rows : 1
    readonly property int verticalStep: horizontal ? 1 : columns
    // A single row with an odd column count keeps the selection in the middle slot while scrolling.
    readonly property bool centerSelection: rows === 1 && columns % 2 === 1
    // Single-row strips that scroll sideways; vertical single rows page a whole row at a time.
    readonly property bool centeredStrip: centerSelection && (wrapping || horizontal)
    readonly property int scrollDuration: ThemeService.settings.scrollAnimationDuration ?? 180
    // Source of truth for the selection; the grid only reads it, the carousel mirrors it.
    property int selectedIndex: 0
    property real wheelRemainder: 0
    // Set while the selection jumps to the active wallpaper, so opening snaps there instead of sliding.
    property bool snapReveal: false
    // Delete mode: clicks mark wallpapers (keyed by path, so filtering and rescans can't shift them)
    // instead of applying them; the header check then asks for confirmation before anything is removed.
    property bool deleteMode: false
    property var marked: ({})
    readonly property int markedCount: Object.keys(marked).length
    // Rename: right-click opens an inline editor under the thumbnail. `followPath` is where the file
    // should land, so the selection stays on it after the list re-sorts.
    property string renamingPath: ""
    property string followPath: ""
    // The editor currently shown (the grid and the carousel both build cards, only one is visible).
    property Item editor: null

    implicitWidth: 48 + columns * cellWidth
    implicitHeight: 48 + header.implicitHeight + content.spacing + searchField.implicitHeight + content.spacing + gallery.height
        + (status.visible ? content.spacing + status.implicitHeight : 0)

    Component.onCompleted: { searchField.forceActiveFocus(); Qt.callLater(selectActiveWallpaper); }
    Component.onDestruction: exitDeleteMode()
    onVisibleChanged: {
        cancelRename();
        sortMenuOpen = false;
        if (visible) {
            searchField.forceActiveFocus();
            selectActiveWallpaper();
            Qt.callLater(revealSelection, true);
        } else exitDeleteMode();
    }
    onSelectedIndexChanged: if (!snapReveal) revealSelection(false)
    onWrappingChanged: { selectedIndex = clampIndex(selectedIndex); Qt.callLater(revealSelection, true); }
    onRowsChanged: Qt.callLater(revealSelection, true)
    onColumnsChanged: Qt.callLater(revealSelection, true)
    onHorizontalChanged: Qt.callLater(revealSelection, true)
    onCenteredStripChanged: Qt.callLater(revealSelection, true)

    FilteredListModel {
        id: filteredWallpapers
        sourceModel: WallpaperService.currentModel
        // Both functions read service state without tracking it; the Connections below rebuild on favorites changes.
        filter: WallpaperService.favoritesOnly ? (row => WallpaperService.favoriteSet[row.path] === true) : null
        comparator: root.comparatorFor(WallpaperService.sortMode)
        searchText: searchField.text
        roles: ["path", "thumbnail", "added"]
        searchRoles: ["path"]
        searchFileNames: true
        onRebuilt: function(resetSelection) {
            let index = model.count > 0 ? (resetSelection ? 0 : Math.max(0, Math.min(root.selectedIndex, model.count - 1))) : -1;
            // A cleared or changed list reopens on the applied wallpaper, unless a query is steering the results.
            if (resetSelection && searchField.text.length === 0 && root.rows === 1) {
                const active = root.activeIndex();
                if (active >= 0) index = active;
            }
            // Resets snap straight to the final index so the carousel never slides through a stale one.
            root.snapReveal = resetSelection;
            root.selectedIndex = index;
            root.snapReveal = false;
            if (!resetSelection && root.followPath) {
                const moved = root.indexOfPath(root.followPath);
                if (moved >= 0) { root.snapReveal = true; root.selectedIndex = moved; root.snapReveal = false; root.followPath = ""; }
            }
            if (resetSelection) gallery.positionViewAtBeginning();
            Qt.callLater(root.revealSelection, true);
        }
    }

    function activeIndex() {
        const model = filteredWallpapers.model;
        for (let i = 0; i < model.count; i++)
            if (model.get(i).path === ThemeService.wallpaper) return i;
        return -1;
    }

    // Single-row layouts open on the applied wallpaper: odd column counts keep it in the middle
    // slot, even ones bring it into view. Opening ignores a leftover query when the match is listed.
    function selectActiveWallpaper() {
        if (rows !== 1) return;
        const index = activeIndex();
        if (index < 0) return;
        snapReveal = true;
        selectedIndex = index;
        snapReveal = false;
        revealSelection(true);
    }

    function clampIndex(index) {
        const count = filteredWallpapers.model.count;
        if (count <= 0) return -1;
        if (wrapping) return ((index % count) + count) % count;
        return Math.max(0, Math.min(index, count - 1));
    }

    function stepSelection(delta) {
        selectedIndex = clampIndex(selectedIndex + delta);
    }

    // Wheel input for strips that scroll by selection: notches step one card each, touchpads step
    // once per card width of travel.
    function wheelSelect(event) {
        const pixel = event.pixelDelta.x !== 0 ? event.pixelDelta.x : event.pixelDelta.y;
        const angle = event.angleDelta.x !== 0 ? event.angleDelta.x : event.angleDelta.y;
        const unit = pixel !== 0 ? cellWidth : 120;
        wheelRemainder += pixel !== 0 ? pixel : angle;
        const steps = Math.trunc(wheelRemainder / unit);
        if (steps !== 0) {
            wheelRemainder -= steps * unit;
            stepSelection(-steps);
        }
        event.accepted = true;
    }

    // Keeps the selected card on screen. Explicit scrolling replaces GridView's own current-item
    // tracking, which jumped without animation and could lose the selection after wheel scrolling.
    function revealSelection(instant) {
        const index = selectedIndex;
        if (index < 0) return;
        if (wrapping) {
            if (instant) carousel.positionViewAtIndex(index, PathView.SnapPosition);
            else carousel.currentIndex = index;
            return;
        }
        const line = Math.floor(index / (horizontal ? rows : columns));
        const extent = horizontal ? cellWidth : cellHeight;
        const viewport = horizontal ? gallery.width : gallery.height;
        const start = (horizontal ? gallery.originX : gallery.originY) + line * extent;
        if (centeredStrip) {
            // Centre the selected card; SmoothScroll clamps this at either end of the strip.
            wheelScroll.scrollTo(start - (viewport - extent) / 2, instant);
            return;
        }
        const current = wheelScroll.animating && !instant ? wheelScroll.destination : (horizontal ? gallery.contentX : gallery.contentY);
        if (start < current) wheelScroll.scrollTo(start, instant);
        else if (start + extent > current + viewport) wheelScroll.scrollTo(start + extent - viewport, instant);
    }

    function activate(path) {
        // Marks are frozen while the confirmation is up so it always matches what gets deleted.
        if (ThemeService.busy || StatusManager.confirming) return;
        if (deleteMode) toggleMark(path);
        else WallpaperService.apply(path);
    }

    function applySelectedWallpaper() {
        const index = root.selectedIndex;
        if (index >= 0 && index < filteredWallpapers.model.count)
            activate(filteredWallpapers.model.get(index).path);
    }

    // Names compare case-insensitively with digit runs as numbers, so "wall 2" precedes "wall 10".
    function naturalCompare(a, b) {
        const left = a.toLowerCase().split(/(\d+)/);
        const right = b.toLowerCase().split(/(\d+)/);
        for (let i = 0; i < Math.min(left.length, right.length); i++) {
            if (left[i] === right[i]) continue;
            if (i % 2 === 1) {
                const difference = Number(left[i]) - Number(right[i]);
                if (difference !== 0) return difference;
            }
            return left[i] < right[i] ? -1 : 1;
        }
        return left.length - right.length;
    }
    function comparatorFor(mode) {
        const sign = mode.endsWith("desc") ? -1 : 1;
        const byName = (a, b) => naturalCompare(a.path.split("/").pop(), b.path.split("/").pop()) || naturalCompare(a.path, b.path);
        if (mode.startsWith("added")) return (a, b) => sign * ((a.added || 0) - (b.added || 0)) || byName(a, b);
        return (a, b) => sign * byName(a, b);
    }

    // The selected card keeps its place when the list is re-ordered or filtered.
    function followSelection() {
        const index = selectedIndex;
        if (index < 0 || index >= filteredWallpapers.model.count) return;
        followPath = filteredWallpapers.model.get(index).path;
        followTimer.restart();
    }

    function toggleFavorite(path) {
        WallpaperService.toggleFavorite(path);
    }

    function toggleFavoritesOnly() {
        followSelection();
        WallpaperService.toggleFavoritesOnly();
    }

    property bool sortMenuOpen: false
    function chooseSort(mode) {
        sortMenuOpen = false;
        followSelection();
        WallpaperService.setSort(mode);
    }

    function toggleMark(path) {
        const next = Object.assign({}, marked);
        if (next[path]) delete next[path];
        else next[path] = true;
        marked = next;
    }

    // Marks for files that vanished (deleted elsewhere) would inflate the count.
    function pruneMarks() {
        const present = {};
        for (let i = 0; i < WallpaperService.allWallpapers.count; i++) present[WallpaperService.allWallpapers.get(i).path] = true;
        const next = {};
        for (const path of Object.keys(marked)) if (present[path]) next[path] = true;
        if (Object.keys(next).length !== markedCount) marked = next;
    }

    function exitDeleteMode() {
        if (StatusManager.confirming && deleteMode) StatusManager.resolveConfirm(false);
        deleteMode = false;
        marked = ({});
    }

    function toggleDeleteMode() {
        // Editing a name and delete mode never run together.
        if (renamingPath) return;
        if (deleteMode) exitDeleteMode();
        else deleteMode = true;
    }

    function indexOfPath(path) {
        const model = filteredWallpapers.model;
        for (let i = 0; i < model.count; i++)
            if (model.get(i).path === path) return i;
        return -1;
    }

    function fileStem(path) { return path.split("/").pop().replace(/\.[^.]+$/, ""); }
    function fileSuffix(path) {
        const match = path.split("/").pop().match(/\.[^.]+$/);
        return match ? match[0] : "";
    }

    function startRename(index, path) {
        if (ThemeService.busy || StatusManager.confirming || deleteMode) return;
        selectedIndex = index;
        renamingPath = path;
    }

    // The header check saves what the editor holds, exactly like Enter.
    function commitEditor() {
        if (renamingPath && editor) commitRename(renamingPath, editor.text);
    }

    function insideItem(item, scenePoint) {
        return !!item && item.visible && item.contains(item.mapFromItem(null, scenePoint.x, scenePoint.y));
    }

    function cancelRename() {
        if (!renamingPath) return;
        renamingPath = "";
        focusGallery();
    }

    // The controller validates the name and keeps the extension; the prediction only steers the selection.
    function commitRename(path, value) {
        let stem = value.trim();
        const suffix = fileSuffix(path);
        if (suffix && stem.toLowerCase().endsWith(suffix.toLowerCase())) stem = stem.slice(0, -suffix.length).trim();
        renamingPath = "";
        focusGallery();
        if (!stem || stem === fileStem(path) || ThemeService.busy) return;
        followPath = path.slice(0, path.lastIndexOf("/") + 1) + stem + suffix;
        followTimer.restart();
        WallpaperService.rename(path, stem);
    }

    Timer {
        id: followTimer
        interval: 6000
        onTriggered: root.followPath = ""
    }

    function requestDelete() {
        if (ThemeService.busy || markedCount === 0) return;
        const paths = Object.keys(marked);
        const count = paths.length;
        const replacesApplied = paths.includes(ThemeService.wallpaper);
        StatusManager.confirm({
            monitorName: IslandState.panelMonitorName,
            title: "Delete " + count + (count === 1 ? " wallpaper?" : " wallpapers?"),
            detail: replacesApplied ? "Applied wallpaper will be replaced with a random one."
                : "Files are removed from disk.",
            acceptLabel: "Delete",
            onAccepted: function() {
                WallpaperService.remove(paths);
                root.deleteMode = false;
                root.marked = ({});
            }
        });
    }

    // The ordering function reads the favorites without tracking them, so changes re-sort explicitly.
    Connections {
        target: WallpaperService
        function onFavoriteSetChanged() { if (WallpaperService.favoritesOnly) filteredWallpapers.rebuild(false); }
    }

    Connections {
        target: WallpaperService.allWallpapers
        function onCountChanged() { if (root.markedCount > 0) root.pruneMarks(); }
    }

    function focusGallery() {
        searchField.focus = false;
        root.forceActiveFocus();
    }

    // Shared by the grid and the wrapping carousel so both render identical cards.
    Component {
        id: wallpaperCell
        Item {
            required property int index
            required property string path
            required property string thumbnail
            readonly property bool renaming: root.renamingPath === path
            objectName: "wallpaper-cell"
            width: root.cellWidth
            height: root.cellHeight
            WallpaperCard {
                id: thumbnail
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 12
                height: 100
                imageSource: parent.thumbnail
                selected: index === root.selectedIndex
                active: path === ThemeService.wallpaper
                blurActive: WallpaperService.activeBlur
                blurStrength: WallpaperService.blurStrength
                blurRadius: WallpaperService.blurRadius
                blurPasses: WallpaperService.blurPasses
                marked: root.marked[path] === true
                favorite: WallpaperService.favoriteSet[path] === true
                favoriteHint: !root.deleteMode && !parent.renaming
                    && (cellHover.hovered || index === root.selectedIndex)
            }
            HoverHandler { id: cellHover }
            UiText {
                visible: !parent.renaming
                anchors.top: thumbnail.bottom
                anchors.topMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 14
                text: path.split("/").pop().replace(/^[0-9]+[-_]*/, "").replace(/\.[^.]+$/, "").replace(/[-_]/g, " ")
                color: path === ThemeService.wallpaper ? Theme.accent : Theme.textSecondary
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: 12
            }
            MouseArea {
                anchors.fill: parent
                enabled: !ThemeService.busy
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                // Clicking hands keys to the gallery so arrow keys keep working from the clicked card.
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) { root.startRename(index, path); return; }
                    // A click while an editor is open only dismisses it.
                    if (root.renamingPath) { root.cancelRename(); return; }
                    root.focusGallery();
                    root.selectedIndex = index;
                    root.activate(path);
                }
            }
            // Declared after the cell's click area so it takes clicks on the badge before apply does.
            MouseArea {
                objectName: "wallpaper-favorite-button"
                anchors.top: thumbnail.top
                anchors.left: thumbnail.left
                width: 40
                height: 40
                enabled: !root.deleteMode && !parent.renaming && !ThemeService.busy
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: WallpaperService.favoriteSet[path] === true ? "Remove from favorites" : "Add to favorites"
                onClicked: {
                    root.focusGallery();
                    root.toggleFavorite(path);
                }
            }
            RenameField {
                id: renameField
                objectName: "wallpaper-rename-field"
                visible: parent.renaming
                anchors.top: thumbnail.bottom
                anchors.topMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 14
                height: 24
                suffix: root.fileSuffix(path)
                onVisibleChanged: {
                    if (visible) { text = root.fileStem(path); root.editor = renameField; begin(); }
                    else if (root.editor === renameField) root.editor = null;
                }
                onCommitted: value => root.commitRename(path, value)
                onCancelled: if (parent.renaming) root.cancelRename()
            }
        }
    }

    // Anywhere else on the panel abandons a name edit; only Enter or the header check saves it.
    // A passive tap handler sees clicks that child mouse areas also take.
    TapHandler {
        enabled: root.renamingPath !== ""
        onTapped: eventPoint => {
            if (root.insideItem(root.editor, eventPoint.scenePosition)) return;
            if (root.insideItem(header.editConfirmButton, eventPoint.scenePosition)) return;
            root.cancelRename();
        }
    }

    // Clicking anywhere but the sort button or its menu closes the menu (the button toggles it itself).
    TapHandler {
        enabled: root.sortMenuOpen
        onTapped: eventPoint => {
            if (root.insideItem(sortMenu, eventPoint.scenePosition)) return;
            if (root.insideItem(header.sortButton, eventPoint.scenePosition)) return;
            root.sortMenuOpen = false;
        }
    }

    Keys.onEscapePressed: {
        if (sortMenuOpen) sortMenuOpen = false;
        else if (StatusManager.confirming) StatusManager.resolveConfirm(false);
        else if (deleteMode) exitDeleteMode();
        else IslandController.reset();
    }
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            searchField.forceActiveFocus();
            event.accepted = true;
            return;
        }
        if (searchField.activeFocus || renamingPath) return;
        let index = root.selectedIndex;
        if (event.key === Qt.Key_H || event.key === Qt.Key_Left) index -= root.horizontalStep;
        else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) index += root.horizontalStep;
        else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) index += root.verticalStep;
        else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
            // Up from the first row returns to the search field, like the menu grid.
            const atTop = !root.wrapping && (root.horizontal ? index % root.rows === 0 : index < root.columns);
            if (atTop) {
                searchField.forceActiveFocus();
                event.accepted = true;
                return;
            }
            index -= root.verticalStep;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.applySelectedWallpaper();
            event.accepted = true;
            return;
        } else return;
        root.selectedIndex = root.clampIndex(index);
        event.accepted = true;
    }

    Column {
        id: content
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12
        PanelHeader {
            id: header
            title: root.deleteMode ? "Wallpapers • Delete mode active" : "Wallpapers"
            scrollTargets: [root.wrapping ? carousel : gallery]
            onBack: IslandController.openNavigation()
            titleClickable: !root.deleteMode
            titleDescription: "Browse Wallpapers"
            onTitleClicked: IslandController.openWallhaven()
            favoritesVisible: true
            favoritesActive: WallpaperService.favoritesOnly
            favoritesDescription: WallpaperService.favoritesOnly ? "Showing favorites only" : "Show favorites only"
            onFavoritesToggled: root.toggleFavoritesOnly()
            folderVisible: WallpaperService.directory !== ""
            folderDescription: "Open wallpaper folder"
            onFolderClicked: WallpaperService.openDirectory()
            sortVisible: true
            sortActive: WallpaperService.sortMode !== "name-asc" || root.sortMenuOpen
            sortIcon: WallpaperService.sortMode.endsWith("desc") ? "../assets/icons/sort-desc.svg" : "../assets/icons/sort-asc.svg"
            sortDescription: "Sort: " + WallpaperService.sortLabels[WallpaperService.sortMode]
            onSortToggled: root.sortMenuOpen = !root.sortMenuOpen
            deleteVisible: true
            deleteActive: root.deleteMode
            deleteConfirmVisible: root.deleteMode && root.markedCount > 0
            deleteEnabled: root.renamingPath === ""
            editConfirmVisible: root.renamingPath !== ""
            deleteDescription: root.deleteMode ? "Cancel delete" : "Delete wallpapers"
            deleteConfirmDescription: "Delete " + root.markedCount + " selected"
            onDeleteToggled: root.toggleDeleteMode()
            onDeleteConfirmed: root.requestDelete()
            onEditConfirmed: root.commitEditor()
        }
        SearchField {
            id: searchField
            width: parent.width
            placeholderText: "Search wallpapers…"
            onNavigateDown: root.focusGallery()
            onAccepted: root.applySelectedWallpaper()
            // With no query to edit, Left/Right browse the gallery while typing stays available.
            Keys.onLeftPressed: event => {
                if (text.length === 0) root.stepSelection(-root.horizontalStep);
                else event.accepted = false;
            }
            Keys.onRightPressed: event => {
                if (text.length === 0) root.stepSelection(root.horizontalStep);
                else event.accepted = false;
            }
        }
        GridView {
            id: gallery
            readonly property bool scrollAnimationRunning: wheelScroll.animating
            readonly property bool scrollHorizontal: root.horizontal
            // Eases wheel notches along whichever axis the gallery flows.
            SmoothScroll { id: wheelScroll; scrollTarget: gallery; horizontal: root.horizontal; wheelEnabled: !root.centeredStrip }
            // Centred strips scroll by moving the selection so the middle card stays highlighted.
            WheelHandler {
                parent: gallery
                target: null
                enabled: root.centeredStrip && !root.wrapping
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => root.wheelSelect(event)
            }
            visible: !root.wrapping
            width: root.columns * root.cellWidth
            height: root.cellHeight * root.rows
            clip: true
            model: filteredWallpapers.model
            currentIndex: -1
            cellWidth: root.cellWidth
            cellHeight: root.cellHeight
            flow: root.horizontal ? GridView.FlowTopToBottom : GridView.FlowLeftToRight
            snapMode: GridView.NoSnap
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: false
            delegate: wallpaperCell
            UiText {
                anchors.centerIn: parent
                width: parent.width
                visible: filteredWallpapers.model.count === 0
                text: ThemeService.error || (searchField.text.trim() ? "No wallpapers match your search."
                    : WallpaperService.favoritesOnly ? "No favorite wallpapers yet. Tap a star to add one." : "No wallpapers found for this theme.")
                color: ThemeService.error ? Theme.danger : Theme.textSecondary
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                font.pixelSize: 13
            }
        }
        // Wrapping carousel for single-row layouts: the current item sits in the first visible slot,
        // or the middle one for odd column counts, and the path wraps the model, so stepping past
        // either end cycles through the wallpapers.
        PathView {
            id: carousel
            visible: root.wrapping
            width: root.columns * root.cellWidth
            height: root.cellHeight
            clip: true
            model: filteredWallpapers.model
            currentIndex: 0
            onCurrentIndexChanged: if (root.wrapping && root.selectedIndex !== currentIndex) root.selectedIndex = currentIndex
            // One hidden buffer slot on each side lets cards slide in and out instead of popping.
            pathItemCount: root.columns + 2
            highlightRangeMode: PathView.StrictlyEnforceRange
            // Slot 0 is the leading buffer, so slot 1 is the first visible card.
            readonly property int highlightSlot: 1 + (root.centerSelection ? (root.columns - 1) / 2 : 0)
            preferredHighlightBegin: highlightSlot / pathItemCount
            preferredHighlightEnd: highlightSlot / pathItemCount
            // Follows the scroll smoothing setting so wheel steps ease like the vertical gallery.
            highlightMoveDuration: Math.max(1, root.scrollDuration)
            // PathView centres delegates on the path, so slots sit at half-cell offsets starting one cell left.
            path: Path {
                startX: -root.cellWidth / 2
                startY: root.cellHeight / 2
                PathLine { x: (carousel.pathItemCount - 0.5) * root.cellWidth; y: root.cellHeight / 2 }
            }
            delegate: wallpaperCell
            // The loop has no ends, so progress follows the selection and restarts when it wraps.
            readonly property real reportedProgress: count > 0 ? (root.selectedIndex + 1) / count : 1
            WheelHandler {
                parent: carousel
                target: null
                enabled: root.wrapping
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => root.wheelSelect(event)
            }
        }
        // Dynamic themes regenerate the palette from the wallpaper, which takes a moment.
        UiText {
            id: status
            width: parent.width
            text: ThemeService.error && filteredWallpapers.model.count > 0 ? ThemeService.error
                : WallpaperService.favoritesNotice ? WallpaperService.favoritesNotice
                : ThemeService.busy && ThemeService.currentAction !== "setting" && ThemeService.state.source === "dynamic" ? "Applying…" : ""
            visible: text.length > 0
            color: ThemeService.error ? Theme.danger : WallpaperService.favoritesNotice ? Theme.warning : Theme.textSecondary
            wrapMode: Text.Wrap
            font.pixelSize: 13
        }
    }

    // Sort menu: drops from the header's sort button over the search field and gallery.
    Rectangle {
        id: sortMenu
        objectName: "wallpaper-sort-menu"
        z: 10
        visible: root.sortMenuOpen
        anchors.right: parent.right
        anchors.rightMargin: 24 + 36 + 8
        y: 24 + header.height + 2
        width: 200
        height: sortColumn.implicitHeight + 12
        radius: 14
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        Column {
            id: sortColumn
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2
            Repeater {
                model: WallpaperService.sortModes
                delegate: Rectangle {
                    required property string modelData
                    objectName: "wallpaper-sort-" + modelData
                    width: sortColumn.width
                    height: 32
                    radius: 10
                    color: sortMouse.containsMouse ? Theme.surfaceVariant : "transparent"
                    UiText {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.right: check.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: WallpaperService.sortLabels[parent.modelData]
                        color: parent.modelData === WallpaperService.sortMode ? Theme.accent : Theme.textPrimary
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                    SvgIcon {
                        id: check
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: parent.modelData === WallpaperService.sortMode
                        source: "../assets/icons/check.svg"
                        color: Theme.accent
                        size: 14
                    }
                    MouseArea {
                        id: sortMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.chooseSort(parent.modelData)
                    }
                }
            }
        }
    }
}
