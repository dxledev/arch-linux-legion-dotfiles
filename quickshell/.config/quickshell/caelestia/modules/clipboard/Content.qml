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
    property string activeFilter: "all"
    readonly property var activeList: tab === 0 ? historyList : favoritesList

    property string appliedQuery: ""
    property real historyScroll: 0
    property real favoritesScroll: 0
    property string historySelection: ""
    property string favoritesSelection: ""
    property bool clearConfirmationOpen: false
    property string clearError: ""
    property bool deleteConfirmationOpen: false
    property string deleteError: ""
    property string pendingFavoriteKey: ""
    property bool deletePending: false
    readonly property real confirmationHeight: clearConfirmationOpen || deleteConfirmationOpen ? clearConfirmation.height + Style.gap : 0

    function switchFilter(value: string): void {
        if (ClipboardState.controller.clearingHistory || deletePending)
            return;
        switchTab(value === "pinned" ? 1 : 0);
        activeFilter = value;
        Qt.callLater(() => activeList.restoreSelection());
    }

    function focusSearch(): void {
        search.forceActiveFocus();
    }

    function switchTab(next: int): void {
        if (ClipboardState.controller.clearingHistory || deletePending)
            return;
        if (tab === next)
            return;
        clearConfirmationOpen = false;
        deleteConfirmationOpen = false;
        clearError = "";
        deleteError = "";
        pendingFavoriteKey = "";
        saveCurrentTab();
        tab = next;
        Qt.callLater(() => {
            const target = tab === 0 ? historyList : favoritesList;
            target.listView.contentY = tab === 0 ? historyScroll : favoritesScroll;
            target.restoreSelection();
        });
    }

    function saveCurrentTab(): void {
        if (tab === 0) {
            historyScroll = historyList.listView.contentY;
            historySelection = historyList.selectedKey;
        } else {
            favoritesScroll = favoritesList.listView.contentY;
            favoritesSelection = favoritesList.selectedKey;
        }
    }

    function applySearch(): void {
        appliedQuery = search.text;
    }

    function resetForOpen(): void {
        clearConfirmationOpen = false;
        deleteConfirmationOpen = false;
        clearError = "";
        deleteError = "";
        pendingFavoriteKey = "";
        deletePending = false;
        tab = 0;
        activeFilter = "all";
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
        if (ClipboardState.controller.clearingHistory || deletePending)
            return;
        deleteConfirmationOpen = false;
        deleteError = "";
        pendingFavoriteKey = "";
        clearError = "";
        clearConfirmationOpen = true;
    }

    function requestFavoriteDelete(key: string): void {
        if (deletePending)
            return;
        clearConfirmationOpen = false;
        clearError = "";
        pendingFavoriteKey = key;
        deleteError = "";
        deleteConfirmationOpen = true;
    }

    function cancelClear(): void {
        const focusTarget = ClipboardState.controller.clearingHistory ? closeButton : clearButton;
        clearConfirmationOpen = false;
        clearError = "";
        Qt.callLater(() => focusTarget.forceActiveFocus());
    }

    function cancelFavoriteDelete(): void {
        if (deletePending)
            return;
        deleteConfirmationOpen = false;
        deleteError = "";
        pendingFavoriteKey = "";
        Qt.callLater(() => search.forceActiveFocus());
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

    function confirmFavoriteDelete(): void {
        if (deletePending || pendingFavoriteKey.length === 0)
            return;
        deletePending = true;
        ClipboardState.controller.deleteFavoriteEntry(pendingFavoriteKey);
    }

    Component.onCompleted: Qt.callLater(focusSearch)

    Keys.onEscapePressed: event => {
        if (deleteConfirmationOpen)
            cancelFavoriteDelete();
        else if (clearConfirmationOpen)
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
                KeyNavigation.tab: search
                Keys.onReturnPressed: ClipboardState.close()
                Keys.onSpacePressed: ClipboardState.close()
            }
        }

        SearchBar {
            id: search

            objectName: "clipboardSearch"
            Layout.fillWidth: true
            placeholderText: "Search clipboard…"
            KeyNavigation.tab: search.text.length > 0 ? search.clearIcon : filterButtons.itemAt(0)
            onTextChanged: searchDelay.restart()

            Keys.onEscapePressed: event => {
                if (root.deleteConfirmationOpen)
                    root.cancelFavoriteDelete();
                else if (root.clearConfirmationOpen)
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
                search.clearIcon.KeyNavigation.tab = filterButtons.itemAt(0);
            }
        }

        Flow {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            spacing: 6

            Repeater {
                id: filterButtons
                model: [
                    {value: "all", label: "All", icon: "view_list"},
                    {value: "pinned", label: "Pinned", icon: "star"},
                    {value: "text", label: "Text", icon: "description"},
                    {value: "link", label: "Links", icon: "link"},
                    {value: "image", label: "Images", icon: "image"},
                    {value: "files", label: "Files", icon: "folder"},
                    {value: "code", label: "Code", icon: "code"},
                    {value: "json", label: "JSON", icon: "data_object"},
                    {value: "color", label: "Colors", icon: "palette"}
                ]

                IconTextButton {
                    required property var modelData
                    text: modelData.label
                    icon: modelData.icon
                    font: Tokens.font.label.small
                    verticalPadding: 5
                    horizontalPadding: 12
                    isToggle: true
                    checked: root.activeFilter === modelData.value
                    activeFocusOnTab: true
                    onClicked: {
                        root.switchFilter(modelData.value);
                        internalChecked = checked;
                    }
                    Keys.onReturnPressed: root.switchFilter(modelData.value)
                    Keys.onSpacePressed: root.switchFilter(modelData.value)
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.tab === 1 && search.text.trim().length > 0
            text: "Clear search to reorder pinned entries."
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

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.gap

            Item {
                id: listArea
                Layout.fillWidth: true
                Layout.preferredWidth: root.width * (ClipboardState.options.listRatio ?? 0.48)
                Layout.fillHeight: true
                clip: true

                EntryList {
                    id: historyList
                    anchors.fill: parent
                    visible: root.tab === 0
                    favorites: false
                    sourceModel: ClipboardState.controller.historyModel
                    controller: ClipboardState.controller
                    query: root.appliedQuery
                    searchText: search.text
                    kindFilter: root.activeFilter === "all" || root.activeFilter === "pinned" ? "" : root.activeFilter
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
                    query: root.appliedQuery
                    searchText: search.text
                    selectedKey: root.favoritesSelection
                    onSelectedKeyChanged: if (root.tab === 1) root.favoritesSelection = selectedKey
                    onDeleteFavoriteRequested: key => root.requestFavoriteDelete(key)
                }
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: Style.outline
            }

            PreviewPane {
                Layout.fillWidth: true
                Layout.preferredWidth: root.width * (1 - (ClipboardState.options.listRatio ?? 0.48))
                Layout.fillHeight: true
                entry: root.activeList.selectedEntry
                controller: ClipboardState.controller
            }
        }

        Text {
            Layout.fillWidth: true
            text: `${root.activeList.count} items · ↑/↓ select · Enter copy & close · Double-click copy · Esc close`
            color: Style.muted
            font: Tokens.font.label.small
            elide: Text.ElideRight
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

        function onEntryDeleteCompleted(key: string, favorite: bool, success: bool, errorText: string): void {
            if (!favorite || key !== root.pendingFavoriteKey)
                return;
            root.deletePending = false;
            if (success) {
                root.deleteConfirmationOpen = false;
                root.pendingFavoriteKey = "";
                root.deleteError = "";
                Qt.callLater(() => search.forceActiveFocus());
            } else {
                root.deleteError = errorText;
            }
        }
    }

    ClearConfirmation {
        id: clearConfirmation
        anchors.horizontalCenter: root.horizontalCenter
        anchors.bottom: root.top
        anchors.bottomMargin: visible ? Style.gap : 0
        visible: root.clearConfirmationOpen || root.deleteConfirmationOpen
        title: root.deleteConfirmationOpen ? "Delete pinned entry and history entries?"
            : root.tab === 0 ? "Clear clipboard history?" : "Remove all pinned entries?"
        description: root.deleteConfirmationOpen
            ? "This removes the pinned entry and permanently deletes all matching history entries."
            : root.tab === 0
            ? "This permanently removes every item from cliphist."
            : "This removes every pinned entry and its stored payload."
        confirmText: root.deleteConfirmationOpen ? "Delete entry" : root.tab === 0 ? "Clear history" : "Clear pinned"
        errorText: root.deleteConfirmationOpen ? root.deleteError : root.clearError
        busy: ClipboardState.controller.clearingHistory || root.deletePending
        busyText: root.deleteConfirmationOpen ? "Deleting…" : "Clearing…"
        onConfirmed: root.deleteConfirmationOpen ? root.confirmFavoriteDelete() : root.confirmClear()
        onCancelled: root.deleteConfirmationOpen ? root.cancelFavoriteDelete() : root.cancelClear()
    }
}
