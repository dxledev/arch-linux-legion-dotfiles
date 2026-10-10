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
    readonly property var entries: searchVisible ? MenuEntries.filterEntries(searchField.text)
        : MenuService.displayedIds.map(id => MenuEntries.findEntryById(id))
    implicitWidth: 460
    implicitHeight: content.implicitHeight + 48
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

    function focusCards() {
        searchField.focus = false;
        menuGrid.forceActiveFocus();
    }

    function openSelected() {
        const entry = entries[menuGrid.currentIndex];
        if (entry) IslandController.openMenuEntry(entry.id);
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
            title: "Menu"
            titleActionIcon: "../assets/icons/search.svg"
            titleActionDescription: root.searchVisible ? "Hide search" : "Search submenus"
            titleActionActive: root.searchVisible
            scrollTargets: [menuGrid]
            onTitleActionClicked: root.toggleSearch()
            onBack: IslandController.openExpanded()
        }
        SearchField {
            id: searchField
            objectName: "menu-search"
            width: parent.width
            visible: root.searchVisible
            placeholderText: "Search submenus…"
            onNavigateDown: root.focusCards()
            onAccepted: root.openSelected()
        }
        GridView {
            id: menuGrid
            objectName: "menu-grid"
            readonly property bool scrollAnimationRunning: wheelScroll.animating
            // Include the last cell's gutter to preserve both cards' original width.
            width: parent.width + 12
            height: 276
            cellWidth: width / 2
            cellHeight: 144
            contentHeight: Math.max(height, Math.ceil(count / 2) * cellHeight - 12)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: true
            keyNavigationWraps: false
            highlightMoveDuration: Theme.animationFast
            model: root.entries
            SmoothScroll { id: wheelScroll; scrollTarget: menuGrid }
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
                pinEnabled: ThemeService.ready && (pinned || MenuService.pinnedIds.length < 4)
                selected: menuGrid.activeFocus && menuGrid.currentIndex === index
                onClicked: IslandController.openMenuEntry(modelData.id)
                onPinClicked: MenuService.togglePin(modelData.id)
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
                if (root.searchVisible && currentIndex < 2) searchField.forceActiveFocus();
                else event.accepted = false;
            }
        }
    }
    Keys.onPressed: function(event) {
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
