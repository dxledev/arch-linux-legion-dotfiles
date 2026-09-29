pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls

FocusScope {
    id: root

    objectName: "clipboardContent"
    readonly property alias searchField: search
    property int tab: 0
    property string historyQuery: ""
    property string favoritesQuery: ""
    property string appliedQuery: ""
    property real historyScroll: 0
    property real favoritesScroll: 0
    property string historySelection: ""
    property string favoritesSelection: ""
    property bool clearConfirmationOpen: false
    property string clearError: ""
    readonly property real confirmationHeight: clearConfirmationOpen ? clearConfirmation.height + Style.gap : 0

    function focusSearch(): void {
        search.forceActiveFocus();
    }

    function switchTab(next: int): void {
        if (ClipboardState.controller.clearingHistory)
            return;
        if (tab === next)
            return;
        clearConfirmationOpen = false;
        clearError = "";
        saveCurrentTab();
        tab = next;
        search.text = tab === 0 ? historyQuery : favoritesQuery;
        appliedQuery = search.text;
        searchDelay.restart();
        Qt.callLater(() => {
            const target = tab === 0 ? historyList : favoritesList;
            target.listView.contentY = tab === 0 ? historyScroll : favoritesScroll;
            target.restoreSelection();
        });
    }

    function saveCurrentTab(): void {
        if (tab === 0) {
            historyQuery = search.text;
            historyScroll = historyList.listView.contentY;
            historySelection = historyList.selectedKey;
        } else {
            favoritesQuery = search.text;
            favoritesScroll = favoritesList.listView.contentY;
            favoritesSelection = favoritesList.selectedKey;
        }
    }

    function applySearch(): void {
        appliedQuery = search.text;
        if (tab === 0)
            historyQuery = search.text;
        else
            favoritesQuery = search.text;
    }

    function resetForOpen(): void {
        clearConfirmationOpen = false;
        clearError = "";
        tab = 0;
        historyQuery = "";
        favoritesQuery = "";
        appliedQuery = "";
        historyScroll = 0;
        favoritesScroll = 0;
        historySelection = "";
        favoritesSelection = "";
        search.text = "";
        historyList.listView.contentY = 0;
        favoritesList.listView.contentY = 0;
        Qt.callLater(focusSearch);
    }

    function requestClear(): void {
        if (ClipboardState.controller.clearingHistory)
            return;
        clearError = "";
        clearConfirmationOpen = true;
    }

    function cancelClear(): void {
        const focusTarget = ClipboardState.controller.clearingHistory ? closeButton : clearButton;
        clearConfirmationOpen = false;
        clearError = "";
        Qt.callLater(() => focusTarget.forceActiveFocus());
    }

    function confirmClear(): void {
        if (tab === 0) {
            ClipboardState.controller.clearHistory();
            return;
        }
        if (ClipboardState.controller.clearFavorites()) {
            clearConfirmationOpen = false;
            clearError = "";
            Qt.callLater(() => clearButton.forceActiveFocus());
        } else {
            clearError = ClipboardState.controller.errorMessage;
        }
    }

    Component.onCompleted: Qt.callLater(focusSearch)

    Keys.onEscapePressed: event => {
        if (clearConfirmationOpen)
            cancelClear();
        else
            ClipboardState.close();
        event.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        radius: Tokens.rounding.extraLarge
        color: Style.panel
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.padding
        spacing: Style.gap

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.gap

            StyledText {
                Layout.fillWidth: true
                text: "Clipboard"
                color: Style.text
                font: Tokens.font.title.medium
            }

            TextButton {
                id: clearButton
                text: "Clear"
                type: TextButton.Text
                activeOnColour: Style.error
                inactiveOnColour: Style.error
                enabled: !ClipboardState.controller.clearingHistory
                onClicked: root.requestClear()
                activeFocusOnTab: true
                stateLayer.manualHoverOverride: activeFocus
                KeyNavigation.tab: closeButton
                Keys.onReturnPressed: root.requestClear()
                Keys.onSpacePressed: root.requestClear()
                Keys.onEscapePressed: event => {
                    root.cancelClear();
                    event.accepted = true;
                }
            }

            TextButton {
                id: closeButton
                text: "Close"
                type: TextButton.Tonal
                onClicked: ClipboardState.close()
                activeFocusOnTab: true
                stateLayer.manualHoverOverride: activeFocus
                KeyNavigation.tab: historyButton
                Keys.onReturnPressed: ClipboardState.close()
                Keys.onSpacePressed: ClipboardState.close()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            TextButton {
                id: historyButton
                Layout.fillWidth: true
                text: "History"
                isToggle: true
                checked: root.tab === 0
                onClicked: root.switchTab(0)
                activeFocusOnTab: true
                stateLayer.manualHoverOverride: activeFocus
                KeyNavigation.tab: favoritesButton
                Keys.onReturnPressed: root.switchTab(0)
                Keys.onSpacePressed: root.switchTab(0)
            }

            TextButton {
                id: favoritesButton
                Layout.fillWidth: true
                text: "Favorites"
                isToggle: true
                checked: root.tab === 1
                onClicked: root.switchTab(1)
                activeFocusOnTab: true
                stateLayer.manualHoverOverride: activeFocus
                KeyNavigation.tab: search
                Keys.onReturnPressed: root.switchTab(1)
                Keys.onSpacePressed: root.switchTab(1)
            }
        }

        SearchBar {
            id: search

            objectName: "clipboardSearch"
            Layout.fillWidth: true
            placeholderText: root.tab === 0 ? "Search clipboard history" : "Search favorites"
            KeyNavigation.tab: search.text.length > 0 ? search.clearIcon : clearButton
            onTextChanged: searchDelay.restart()

            Keys.onEscapePressed: event => {
                if (root.clearConfirmationOpen)
                    root.cancelClear();
                else
                    ClipboardState.close();
                event.accepted = true;
            }
            Keys.onUpPressed: event => {
                (root.tab === 0 ? historyList : favoritesList).selectRelative(-1);
                event.accepted = true;
            }
            Keys.onDownPressed: event => {
                (root.tab === 0 ? historyList : favoritesList).selectRelative(1);
                event.accepted = true;
            }
            onAccepted: (root.tab === 0 ? historyList : favoritesList).copySelected()

            Component.onCompleted: {
                search.clearIcon.activeFocusOnTab = true;
                search.clearIcon.KeyNavigation.tab = clearButton;
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.tab === 1 && search.text.trim().length > 0
            text: "Clear search to reorder favorites."
            color: Style.muted
            font: Tokens.font.label.small
        }

        Text {
            Layout.fillWidth: true
            visible: ClipboardState.controller.errorMessage.length > 0
            text: ClipboardState.controller.errorMessage
            color: Style.error
            wrapMode: Text.WordWrap
            font: Tokens.font.label.small
        }

        Item {
            id: listArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            EntryList {
                id: historyList
                anchors.fill: parent
                visible: root.tab === 0
                favorites: false
                sourceModel: ClipboardState.controller.historyModel
                controller: ClipboardState.controller
                query: root.tab === 0 ? root.appliedQuery : root.historyQuery
                searchText: root.tab === 0 ? search.text : root.historyQuery
                selectedKey: root.historySelection
                onSelectedKeyChanged: if (root.tab === 0) root.historySelection = selectedKey
            }

            EntryList {
                id: favoritesList
                anchors.fill: parent
                visible: root.tab === 1
                favorites: true
                sourceModel: ClipboardState.controller.favoritesModel
                controller: ClipboardState.controller
                query: root.tab === 1 ? root.appliedQuery : root.favoritesQuery
                searchText: root.tab === 1 ? search.text : root.favoritesQuery
                selectedKey: root.favoritesSelection
                onSelectedKeyChanged: if (root.tab === 1) root.favoritesSelection = selectedKey
            }
        }
    }

    Timer {
        id: searchDelay
        interval: Math.max(0, ClipboardState.options.searchDebounceMs ?? 150)
        onTriggered: root.applySearch()
    }

    Connections {
        target: ClipboardState
        function onOpeningIdChanged(): void {
            root.resetForOpen();
        }
    }

    Connections {
        target: ClipboardState.controller
        function onHistoryClearCompleted(success: bool, errorText: string): void {
            if (success) {
                root.clearConfirmationOpen = false;
                root.clearError = "";
                Qt.callLater(() => clearButton.forceActiveFocus());
            } else {
                root.clearError = errorText;
            }
        }
    }

    ClearConfirmation {
        id: clearConfirmation
        anchors.horizontalCenter: root.horizontalCenter
        anchors.bottom: root.top
        anchors.bottomMargin: visible ? Style.gap : 0
        visible: root.clearConfirmationOpen
        title: root.tab === 0 ? "Clear clipboard history?" : "Remove all favorites?"
        description: root.tab === 0
            ? "This permanently removes every item from cliphist."
            : "This removes every saved favorite and its stored payload."
        confirmText: root.tab === 0 ? "Clear history" : "Clear favorites"
        errorText: root.clearError
        busy: ClipboardState.controller.clearingHistory
        onConfirmed: root.confirmClear()
        onCancelled: root.cancelClear()
    }
}
