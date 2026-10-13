import QtQuick
import "../components"
import "../core"
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

    implicitWidth: 48 + columns * cellWidth
    implicitHeight: 48 + header.implicitHeight + content.spacing + searchField.implicitHeight + content.spacing + gallery.height
        + (status.visible ? content.spacing + status.implicitHeight : 0)

    Component.onCompleted: searchField.forceActiveFocus()
    onVisibleChanged: if (visible) { searchField.forceActiveFocus(); Qt.callLater(revealSelection, true); }
    onSelectedIndexChanged: revealSelection(false)
    onWrappingChanged: { selectedIndex = clampIndex(selectedIndex); Qt.callLater(revealSelection, true); }
    onRowsChanged: Qt.callLater(revealSelection, true)
    onColumnsChanged: Qt.callLater(revealSelection, true)
    onHorizontalChanged: Qt.callLater(revealSelection, true)
    onCenteredStripChanged: Qt.callLater(revealSelection, true)

    FilteredListModel {
        id: filteredWallpapers
        sourceModel: WallpaperService.currentModel
        searchText: searchField.text
        roles: ["path", "thumbnail"]
        searchRoles: ["path"]
        searchFileNames: true
        onRebuilt: function(resetSelection) {
            root.selectedIndex = model.count > 0 ? (resetSelection ? 0 : Math.max(0, Math.min(root.selectedIndex, model.count - 1))) : -1;
            if (resetSelection) gallery.positionViewAtBeginning();
            Qt.callLater(root.revealSelection, true);
        }
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

    function applySelectedWallpaper() {
        const index = root.selectedIndex;
        if (!ThemeService.busy && index >= 0 && index < filteredWallpapers.model.count)
            WallpaperService.apply(filteredWallpapers.model.get(index).path);
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
            }
            UiText {
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
                cursorShape: Qt.PointingHandCursor
                // Clicking hands keys to the gallery so arrow keys keep working from the clicked card.
                onClicked: { root.focusGallery(); root.selectedIndex = index; WallpaperService.apply(path); }
            }
        }
    }

    Keys.onEscapePressed: IslandController.reset()
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            searchField.forceActiveFocus();
            event.accepted = true;
            return;
        }
        if (searchField.activeFocus) return;
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
            title: "Wallpapers"
            scrollTargets: [root.wrapping ? carousel : gallery]
            onBack: IslandController.openNavigation()
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
                text: ThemeService.error || (searchField.text.trim() ? "No wallpapers match your search." : "No wallpapers found for this theme.")
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
                : ThemeService.busy && ThemeService.state.source === "dynamic" ? "Applying…" : ""
            visible: text.length > 0
            color: ThemeService.error ? Theme.danger : Theme.textSecondary
            wrapMode: Text.Wrap
            font.pixelSize: 13
        }
    }
}
