pragma ComponentBehavior: Bound
import QtQuick
import "../components"
import "../core"
import "../services"
import "../styles"
import "../services/MenuEntries.js" as MenuEntries

FocusScope {
    id: root
    property bool searchVisible: false
    readonly property var entries: searchVisible ? MenuEntries.filterEntries(searchField.text, undefined, MenuService.pinnedIds)
        : MenuService.displayedIds.map(id => MenuEntries.findEntryById(id))
    readonly property int columns: MenuService.columns
    readonly property int rows: MenuService.rows
    // Cards keep their 2x2 size; extra columns widen the panel instead of squeezing cards.
    implicitWidth: 48 + columns * 212 - 12
    // Report the target height so the Island animates once while the search row reveals in step.
    implicitHeight: 48 + header.implicitHeight + content.spacing + searchReveal.targetHeight + menuGrid.height
    Component.onCompleted: forceActiveFocus()

    function toggleSearch() {
        searchVisible = !searchVisible;
        if (searchVisible) searchField.forceActiveFocus();
        else {
            searchField.clear();
            searchField.focus = false;
            root.forceActiveFocus();
        }
    }

    function handleSearchToggle(event) {
        if (event.key !== Qt.Key_Slash || event.modifiers !== Qt.NoModifier) return false;
        toggleSearch();
        event.accepted = true;
        return true;
    }

    function focusCards() {
        searchField.focus = false;
        menuGrid.forceActiveFocus();
    }

    function openSelected() {
        const entry = entries[menuGrid.currentIndex];
        if (entry) IslandController.openMenuEntry(entry.id);
    }

    // Pinned cards lead the unsearched grid, so their indices double as pin positions.
    property int reorderFrom: -1
    property int reorderTarget: -1
    readonly property bool reordering: reorderFrom >= 0

    function beginReorder(index) {
        reorderFrom = index;
        reorderTarget = index;
    }

    function updateReorder(scenePoint) {
        const point = menuGrid.mapFromItem(null, scenePoint.x, scenePoint.y);
        const index = menuGrid.indexAt(point.x + menuGrid.contentX, point.y + menuGrid.contentY);
        // Empty space and unpinned cards keep the last target or clamp to the final pin.
        if (index >= 0) reorderTarget = Math.min(index, MenuService.pinnedIds.length - 1);
    }

    function endReorder(committed, id) {
        const from = reorderFrom;
        const to = reorderTarget;
        reorderFrom = -1;
        reorderTarget = -1;
        // Defer the write so the model rebuild does not run inside the dragged delegate's handler.
        if (committed && from >= 0 && to >= 0 && to !== from) Qt.callLater(MenuService.movePin, id, to);
    }

    onEntriesChanged: {
        if (!menuGrid) return;
        menuGrid.currentIndex = entries.length > 0 ? 0 : -1;
        menuGrid.positionViewAtBeginning();
    }

    Column {
        id: content
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20
        PanelHeader {
            id: header
            title: "Menu"
            titleActionIcon: "../assets/icons/search.svg"
            titleActionDescription: root.searchVisible ? "Hide search" : "Search submenus"
            titleActionActive: root.searchVisible
            scrollTargets: [menuGrid]
            onTitleActionClicked: root.toggleSearch()
            onBack: IslandController.openExpanded()
        }
        Item {
            width: parent.width
            height: searchReveal.height + menuGrid.height
            Item {
                id: searchReveal
                readonly property real targetHeight: root.searchVisible ? searchField.implicitHeight + content.spacing : 0
                // Overhang the clip so fractional panel positions cannot shave the field's side borders.
                x: -2
                width: parent.width + 4
                height: targetHeight
                clip: true
                visible: root.searchVisible || height > 0
                Behavior on height {
                    NumberAnimation {
                        duration: ThemeService.settings.islandAnimationDuration ?? 300
                        easing.type: Theme.animationVertical
                    }
                }
                SearchField {
                    id: searchField
                    objectName: "menu-search"
                    x: 2
                    width: parent.width - 4
                    opacity: searchReveal.targetHeight > 0 ? Math.min(1, searchReveal.height / searchReveal.targetHeight) : 0
                    placeholderText: "Search…"
                    onNavigateDown: root.focusCards()
                    onAccepted: root.openSelected()
                    Keys.onPressed: event => root.handleSearchToggle(event)
                }
            }
            GridView {
                id: menuGrid
                objectName: "menu-grid"
                y: searchReveal.height
                readonly property bool scrollAnimationRunning: wheelScroll.animating
                // Include the last cell's gutter to preserve both cards' original width.
                width: parent.width + 12
                height: root.rows * cellHeight - 12
                cellWidth: width / root.columns
                cellHeight: 144
                // GridView includes the last cell's gutter in its native scroll extent.
                bottomMargin: -12
                interactive: count > MenuService.cardLimit && !root.reordering
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: true
                keyNavigationWraps: false
                highlightMoveDuration: Theme.animationFast
                model: root.entries
                // Each wheel notch moves one full row of search results.
                SmoothScroll { id: wheelScroll; scrollTarget: menuGrid; wheelStep: menuGrid.cellHeight }
                delegate: NavigationCard {
                    required property var modelData
                    required property int index
                    objectName: "menu-entry-" + modelData.id
                    width: menuGrid.cellWidth - 12
                    height: 132
                    title: modelData.title
                    subtitle: modelData.subtitle
                    iconSource: modelData.icon
                    showPin: true
                    pinned: MenuService.isPinned(modelData.id)
                    pinEnabled: ThemeService.ready && (pinned || MenuService.pinnedIds.length < MenuService.cardLimit)
                    selected: menuGrid.activeFocus && menuGrid.currentIndex === index
                    reorderable: pinned && !root.searchVisible && ThemeService.ready
                    dropTarget: root.reordering && root.reorderTarget === index && root.reorderFrom !== index
                    onClicked: IslandController.openMenuEntry(modelData.id)
                    onPinClicked: MenuService.togglePin(modelData.id)
                    onReorderStarted: root.beginReorder(index)
                    onReorderMoved: point => root.updateReorder(point)
                    onReorderFinished: committed => root.endReorder(committed, modelData.id)
                }
                UiText {
                    anchors.centerIn: parent
                    visible: root.entries.length === 0
                    text: "No submenus match your search."
                    color: Theme.textSecondary
                    font.pixelSize: 13
                }
                Keys.onReturnPressed: root.openSelected()
                Keys.onEnterPressed: root.openSelected()
                Keys.onUpPressed: function(event) {
                    if (root.searchVisible && currentIndex < root.columns) searchField.forceActiveFocus();
                    else event.accepted = false;
                }
            }
        }
    }
    Keys.onPressed: function(event) {
        if (handleSearchToggle(event)) return;
        if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            if (!searchVisible) toggleSearch();
            else searchField.forceActiveFocus();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            if (searchVisible) toggleSearch();
            else IslandController.reset();
            event.accepted = true;
        }
    }
}
