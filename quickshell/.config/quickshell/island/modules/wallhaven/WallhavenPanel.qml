import QtQuick
import QtQuick.Controls
import "../../components"
import "../../core"
import "../../services"
import "../../styles"

// Browse Wallpapers: wallhaven search with every API filter, a paginated grid, and a detail pane
// that previews and applies generated palettes (see WallhavenService and integration/wallhaven).
FocusScope {
    id: root
    implicitWidth: 1100
    implicitHeight: 740
    focus: true

    readonly property bool detailOpen: WallhavenService.selectedId.length > 0
    readonly property int detailWidth: 440
    readonly property bool collectionsView: WallhavenService.view === "collections"
    readonly property bool libraryView: WallhavenService.libraryView
    readonly property var sortings: [
        { value: "date_added", label: "Latest" }, { value: "toplist", label: "Top" }, { value: "random", label: "Random" },
        { value: "views", label: "Views" }, { value: "favorites", label: "Favorites" }, { value: "relevance", label: "Relevance" }
    ]

    function focusSearch() {
        if (libraryView) { focusGrid(); return; }
        searchField.forceActiveFocus();
        searchField.selectAll();
    }

    function focusGrid() {
        if (WallhavenService.results.count === 0) return;
        grid.forceActiveFocus();
        if (grid.currentIndex < 0) grid.currentIndex = 0;
    }

    function submit() {
        WallhavenService.setQuery(searchField.text);
        WallhavenService.setView("browse");
        WallhavenService.search();
    }

    Component.onCompleted: {
        WallhavenService.open();
        // The service outlives the panel: a library left open may list files deleted since.
        if (WallhavenService.libraryView) WallhavenService.loadLibrary();
        searchField.forceActiveFocus();
    }

    Keys.onEscapePressed: {
        if (drawer.expanded) drawer.expanded = false;
        else if (root.detailOpen) WallhavenService.closeDetail();
        else IslandController.reset();
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            root.focusSearch();
            event.accepted = true;
        } else if (event.key === Qt.Key_Slash) {
            root.focusSearch();
            event.accepted = true;
        }
    }

    Column {
        id: content
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        PanelHeader {
            id: header
            title: "Browse Wallpapers"
            // The source line doubles as a switch: wallhaven.cc browses online, "Dynamic library" lists the
            // wallpapers already in the Dynamic folder so palettes can be added to them.
            subtitle: root.libraryView
                ? "Dynamic library · " + WallhavenService.libraryItems.length.toLocaleString() + " wallpapers · browse wallhaven.cc"
                : WallhavenService.meta.total > 0
                    ? "wallhaven.cc · " + WallhavenService.meta.total.toLocaleString() + " wallpapers"
                    : "wallhaven.cc"
            subtitleClickable: true
            subtitleDescription: root.libraryView ? "Browse wallhaven.cc" : "Edit palettes of your Dynamic wallpapers"
            onSubtitleClicked: WallhavenService.toggleLibrary()
            trailingText: WallhavenService.hasKey && !root.libraryView ? "API key active" : ""
            scrollTargets: [grid]
            onBack: IslandController.openNavigation()
        }

        // ---- search ---------------------------------------------------------------------------
        Item {
            visible: !root.libraryView
            width: parent.width
            height: 40
            SearchField {
                id: searchField
                objectName: "wallhaven-search"
                anchors.left: parent.left
                anchors.right: searchButton.left
                anchors.rightMargin: 8
                height: parent.height
                text: WallhavenService.filters.q
                placeholderText: "Search wallhaven — tags, +include -exclude, @user, id:123, like:abc123, type:png"
                onTextEdited: WallhavenService.setQuery(text)
                onAccepted: root.submit()
                onNavigateDown: root.focusGrid()
            }
            WallhavenButton {
                id: searchButton
                objectName: "wallhaven-search-button"
                anchors.right: parent.right
                height: parent.height
                primary: true
                text: "Search"
                iconSource: "../assets/icons/search.svg"
                enabled: !WallhavenService.searching
                onClicked: root.submit()
            }
        }

        // ---- sort, view and filters ---------------------------------------------------------------
        Item {
            width: parent.width
            height: 32
            Row {
                id: viewChips
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                WallhavenChip {
                    objectName: "wallhaven-view-browse"
                    text: "Browse"
                    checked: !root.collectionsView && !root.libraryView
                    onClicked: WallhavenService.setView("browse")
                }
                WallhavenChip {
                    objectName: "wallhaven-view-collections"
                    text: "Collections"
                    checked: root.collectionsView
                    onClicked: WallhavenService.setView("collections")
                }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 16; color: Theme.border; visible: !root.collectionsView && !root.libraryView }
                Repeater {
                    model: root.collectionsView || root.libraryView ? [] : root.sortings
                    WallhavenChip {
                        required property var modelData
                        objectName: "wallhaven-sort-" + modelData.value
                        text: modelData.label
                        checked: WallhavenService.filters.sorting === modelData.value
                        onClicked: WallhavenService.setFilter("sorting", modelData.value)
                    }
                }
                IconButton {
                    visible: !root.collectionsView && !root.libraryView
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 30
                    implicitHeight: 30
                    padding: 7
                    iconSource: WallhavenService.filters.order === "desc" ? "../assets/icons/sort-desc.svg" : "../assets/icons/sort-asc.svg"
                    description: WallhavenService.filters.order === "desc" ? "Descending" : "Ascending"
                    onClicked: WallhavenService.setFilter("order", WallhavenService.filters.order === "desc" ? "asc" : "desc")
                }
            }
            WallhavenButton {
                id: filterButton
                objectName: "wallhaven-filters-toggle"
                visible: !root.collectionsView && !root.libraryView
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: 32
                text: WallhavenService.filterCount() > 0 ? "Filters · " + WallhavenService.filterCount() : "Filters"
                iconSource: "../assets/icons/filter.svg"
                onClicked: drawer.expanded = !drawer.expanded
            }
            // Fewer results per page means bigger thumbnails in the same panel.
            Row {
                id: pageSizes
                objectName: "wallhaven-page-sizes"
                anchors.right: filterButton.visible ? filterButton.left : parent.right
                anchors.rightMargin: filterButton.visible ? 12 : 0
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                UiText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Per page"
                    color: Theme.textMuted
                    font.pixelSize: 11
                }
                Repeater {
                    model: WallhavenService.pageSizeOptions
                    WallhavenChip {
                        required property int modelData
                        objectName: "wallhaven-pagesize-" + modelData
                        text: String(modelData)
                        checked: modelData === WallhavenService.effectivePageSize
                        description: "Show " + modelData + " wallpapers per page"
                        onClicked: WallhavenService.setPageSize(modelData)
                    }
                }
            }
        }

        Item {
            visible: !root.collectionsView && !root.libraryView
            width: parent.width
            height: 30
            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: ["General", "Anime", "People"]
                    WallhavenChip {
                        required property string modelData
                        required property int index
                        text: modelData
                        checked: WallhavenService.filters.categories[index] === "1"
                        onClicked: WallhavenService.toggleBit("categories", index)
                    }
                }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 16; color: Theme.border }
                Repeater {
                    model: ["SFW", "Sketchy", "NSFW"]
                    WallhavenChip {
                        required property string modelData
                        required property int index
                        text: modelData
                        tint: index === 0 ? Theme.success : index === 1 ? Theme.warning : Theme.danger
                        checked: WallhavenService.filters.purity[index] === "1"
                        enabled: index < 2 || WallhavenService.hasKey
                        description: index === 2 && !WallhavenService.hasKey ? "NSFW needs a wallhaven API key (Filters)" : ""
                        onClicked: WallhavenService.toggleBit("purity", index)
                    }
                }
            }
            UiText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: WallhavenService.filters.sorting === "random" && WallhavenService.meta.seed ? "Random seed " + WallhavenService.meta.seed : ""
                color: Theme.textMuted
                font.pixelSize: 11
            }
        }

        // Collections: any user's public collections, or yours with an API key.
        Item {
            visible: root.collectionsView
            width: parent.width
            height: 36
            SearchField {
                id: userField
                objectName: "wallhaven-username"
                anchors.left: parent.left
                width: 220
                height: parent.height
                text: WallhavenService.username
                placeholderText: WallhavenService.hasKey ? "Username (blank for yours)" : "wallhaven username"
                onAccepted: { WallhavenService.setUsername(text); WallhavenService.loadCollections(); }
            }
            WallhavenButton {
                id: loadCollections
                anchors.left: userField.right
                anchors.leftMargin: 8
                height: parent.height
                text: "Load"
                onClicked: { WallhavenService.setUsername(userField.text); WallhavenService.loadCollections(); }
            }
            ListView {
                anchors.left: loadCollections.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                height: 30
                anchors.verticalCenter: parent.verticalCenter
                orientation: ListView.Horizontal
                spacing: 6
                clip: true
                model: WallhavenService.collections
                delegate: WallhavenChip {
                    required property var modelData
                    text: modelData.label + " · " + modelData.count
                    checked: WallhavenService.activeCollection !== null && WallhavenService.activeCollection.id === modelData.id
                    onClicked: WallhavenService.openCollection(modelData)
                }
            }
        }

        WallhavenFilters {
            id: drawer
            objectName: "wallhaven-filters"
            visible: !root.libraryView
            width: parent.width
        }

        // ---- results and detail -------------------------------------------------------------------
        Item {
            id: stage
            width: parent.width
            height: parent.height - y

            Item {
                id: gridArea
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: root.detailOpen ? parent.width - root.detailWidth - 12 : parent.width
                Behavior on width { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }

                GridView {
                    id: grid
                    objectName: "wallhaven-grid"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: layout.fits ? layout.columns * layout.cellWidth : parent.width
                    anchors.top: parent.top
                    anchors.bottom: pager.top
                    anchors.bottomMargin: 8
                    // The grid picks the column count that makes the thumbnails largest while the whole page
                    // still fits (cells at most 1.9:1, no shorter than 72px). Only when nothing fits (a short
                    // panel with many results) does it fall back to whole rows that scroll.
                    readonly property int total: WallhavenService.results.count
                    readonly property int slots: total > 0 ? total : WallhavenService.effectivePageSize
                    readonly property var layout: fitLayout(gridArea.width, height, slots)
                    function fitLayout(areaWidth, areaHeight, count) {
                        const fallback = { fits: false, columns: Math.max(2, Math.floor(areaWidth / 190)), cellWidth: 0 };
                        if (count <= 0 || areaWidth <= 0 || areaHeight <= 0) return fallback;
                        let best = null;
                        const limit = Math.max(1, Math.min(count, Math.floor(areaWidth / 150)));
                        for (let c = 1; c <= limit; c++) {
                            const rows = Math.ceil(count / c);
                            const cellH = areaHeight / rows;
                            if (cellH < 72) continue;
                            const size = Math.min(areaWidth / c, cellH * 1.78);
                            if (!best || size > best.size + 0.5) best = { columns: c, size: size, cellH: cellH };
                        }
                        if (!best) {
                            for (let c = fallback.columns; c <= Math.floor(areaWidth / 150); c++)
                                if (Math.ceil(count / c) * (areaWidth / c * 0.55) <= areaHeight) { fallback.columns = c; break; }
                            return fallback;
                        }
                        return { fits: true, columns: best.columns, cellWidth: Math.min(areaWidth / best.columns, best.cellH * 1.9) };
                    }
                    readonly property int columns: layout.columns
                    readonly property int pageRows: Math.max(1, Math.ceil(total / columns))
                    readonly property bool pageFits: total > 0 && layout.fits
                    readonly property int visibleRows: pageFits ? pageRows : Math.max(1, Math.round(height / (cellWidth * 0.66)))
                    cellWidth: layout.fits ? layout.cellWidth : width / columns
                    cellHeight: pageFits ? Math.min(height / pageRows, cellWidth * 0.7) : height / visibleRows
                    clip: true
                    opacity: WallhavenService.searching && count > 0 ? 0.45 : 1
                    Behavior on opacity { NumberAnimation { duration: Theme.animationFast } }
                    currentIndex: -1
                    model: WallhavenService.results
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationEnabled: true
                    highlightFollowsCurrentItem: false
                    SmoothScroll { id: wheelScroll; scrollTarget: grid; wheelStep: grid.cellHeight }
                    // Settle on a whole row after touchpad and drag scrolling.
                    Timer {
                        id: settle
                        interval: 160
                        onTriggered: {
                            if (grid.dragging || grid.flicking || wheelScroll.animating || grid.cellHeight <= 0) return;
                            const target = Math.round(grid.contentY / grid.cellHeight) * grid.cellHeight;
                            if (Math.abs(target - grid.contentY) > 0.5) wheelScroll.scrollTo(target, true);
                        }
                    }
                    onContentYChanged: settle.restart()
                    Connections {
                        target: WallhavenService
                        function onPageLoaded() { grid.positionViewAtBeginning(); }
                    }
                    ScrollBar.vertical: ScrollBar {
                        width: 4
                        contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.textMuted; opacity: 0.5 }
                    }
                    delegate: WallhavenCard {
                        width: grid.cellWidth
                        height: grid.cellHeight
                        onActivated: {
                            grid.currentIndex = index;
                            WallhavenService.select(WallhavenService.rowItem(index));
                        }
                    }
                    Keys.onReturnPressed: if (currentIndex >= 0) WallhavenService.select(WallhavenService.rowItem(currentIndex))
                    Keys.onEnterPressed: if (currentIndex >= 0) WallhavenService.select(WallhavenService.rowItem(currentIndex))
                    Keys.onUpPressed: {
                        if (currentIndex >= 0 && currentIndex < columns) root.focusSearch();
                        else moveCurrentIndexUp();
                    }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_PageDown || ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Right)) {
                            WallhavenService.goToPage(WallhavenService.meta.page + 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_PageUp || ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Left)) {
                            WallhavenService.goToPage(WallhavenService.meta.page - 1);
                            event.accepted = true;
                        }
                    }
                }

                // Placeholders while the first page loads.
                Flow {
                    visible: (WallhavenService.searching || WallhavenService.libraryLoading || !WallhavenService.searched) && WallhavenService.results.count === 0
                        && !(root.collectionsView && WallhavenService.activeCollection === null)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: grid.width
                    clip: true
                    Repeater {
                        model: WallhavenService.effectivePageSize
                        Item {
                            width: grid.cellWidth
                            height: grid.cellHeight
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 6
                                radius: 16
                                color: Theme.surface
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.45; duration: 750; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 1; duration: 750; easing.type: Easing.InOutSine }
                                }
                            }
                        }
                    }
                }

                // Empty and error states.
                Column {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 40, 420)
                    spacing: 12
                    visible: WallhavenService.results.count === 0 && !WallhavenService.searching && !WallhavenService.libraryLoading
                        && (WallhavenService.error.length > 0 || WallhavenService.searched
                            || (root.collectionsView && WallhavenService.activeCollection === null))
                    SvgIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: "../assets/icons/image-search.svg"
                        size: 40
                        color: WallhavenService.error ? Theme.danger : Theme.textMuted
                    }
                    UiText {
                        objectName: "wallhaven-message"
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        color: WallhavenService.error ? Theme.danger : Theme.textSecondary
                        font.pixelSize: 14
                        text: WallhavenService.error
                            ? WallhavenService.error
                            : root.libraryView ? "No wallpapers in your Dynamic folder yet."
                            : root.collectionsView && WallhavenService.activeCollection === null
                                ? (WallhavenService.collectionsError || "Enter a username and load their collections, then pick one.")
                                : "No wallpapers match these filters."
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        WallhavenButton {
                            visible: WallhavenService.error.length > 0
                            text: "Try again"
                            onClicked: root.libraryView ? WallhavenService.loadLibrary() : WallhavenService.search()
                        }
                        WallhavenButton {
                            visible: WallhavenService.error.length === 0 && !root.collectionsView && !root.libraryView
                            text: "Reset filters"
                            onClicked: WallhavenService.resetFilters()
                        }
                    }
                }

                // Pagination bar: previous, a window of page numbers, next, and the position.
                Item {
                    id: pager
                    objectName: "wallhaven-pager"
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: visible ? 34 : 0
                    visible: WallhavenService.results.count > 0 && WallhavenService.meta.lastPage > 1
                    readonly property int current: WallhavenService.meta.page
                    readonly property int last: WallhavenService.meta.lastPage

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        IconButton {
                            objectName: "wallhaven-page-prev"
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 30
                            implicitHeight: 30
                            padding: 7
                            iconSource: "../assets/icons/chevron-left.svg"
                            description: "Previous page"
                            enabled: pager.current > 1 && !WallhavenService.busy
                            opacity: enabled ? 1 : 0.4
                            onClicked: WallhavenService.goToPage(pager.current - 1)
                        }
                        Repeater {
                            model: WallhavenService.pageWindow(pager.current, pager.last)
                            WallhavenChip {
                                required property int modelData
                                objectName: "wallhaven-page-" + modelData
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.max(30, implicitWidth)
                                text: modelData === 0 ? "…" : String(modelData)
                                checked: modelData === pager.current
                                enabled: modelData !== 0 && !WallhavenService.busy
                                opacity: modelData === 0 ? 0.6 : enabled || checked ? 1 : 0.4
                                onClicked: WallhavenService.goToPage(modelData)
                            }
                        }
                        IconButton {
                            objectName: "wallhaven-page-next"
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 30
                            implicitHeight: 30
                            padding: 7
                            iconSource: "../assets/icons/chevron-right.svg"
                            description: "Next page"
                            enabled: pager.current < pager.last && !WallhavenService.busy
                            opacity: enabled ? 1 : 0.4
                            onClicked: WallhavenService.goToPage(pager.current + 1)
                        }
                    }
                    UiText {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !root.detailOpen  // the narrow pager keeps its room for page numbers
                        text: WallhavenService.searching ? "Loading page " + WallhavenService.requestedPage + "…"
                            : "Page " + pager.current + " of " + pager.last.toLocaleString()
                        color: Theme.textMuted
                        font.pixelSize: 11
                    }
                    UiText {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: WallhavenService.error.length === 0 && !root.detailOpen
                        text: ((pager.current - 1) * WallhavenService.meta.perPage + 1).toLocaleString() + "–"
                            + ((pager.current - 1) * WallhavenService.meta.perPage + WallhavenService.results.count).toLocaleString()
                            + " of " + WallhavenService.meta.total.toLocaleString()
                        color: Theme.textMuted
                        font.pixelSize: 11
                    }
                    UiText {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: WallhavenService.error.length > 0
                        text: WallhavenService.error + " · retry"
                        color: Theme.danger
                        font.pixelSize: 11
                        TapHandler { onTapped: WallhavenService.retry() }
                    }
                }
                // Failure on a later page keeps the previous page visible and offers a retry.
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: pager.top
                    anchors.bottomMargin: 14
                    visible: WallhavenService.error.length > 0 && WallhavenService.results.count > 0 && !pager.visible
                    height: 30
                    width: footer.implicitWidth + 28
                    radius: 15
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.border
                    UiText {
                        id: footer
                        anchors.centerIn: parent
                        text: WallhavenService.error + " · retry"
                        color: Theme.danger
                        font.pixelSize: 12
                    }
                    TapHandler { onTapped: WallhavenService.retry() }
                }
            }

            Item {
                id: detailArea
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: root.detailOpen ? root.detailWidth : 0
                clip: true
                visible: width > 0
                Behavior on width { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
                WallhavenDetail {
                    objectName: "wallhaven-detail"
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: root.detailWidth
                }
            }
        }
    }
}
