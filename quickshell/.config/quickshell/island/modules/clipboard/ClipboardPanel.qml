pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components"
import "../../core"
import "../../styles"

FocusScope {
    id: root
    implicitWidth: 900
    implicitHeight: 620
    focus: true

    readonly property var filters: [
        { value: "all", label: "All", icon: "list.svg" },
        { value: "pinned", label: "Pinned", icon: "star.svg" },
        { value: "text", label: "Text", icon: "file-text.svg" },
        { value: "link", label: "Links", icon: "link.svg" },
        { value: "image", label: "Images", icon: "image.svg" },
        { value: "files", label: "Files", icon: "folder.svg" },
        { value: "code", label: "Code", icon: "code.svg" },
        { value: "json", label: "JSON", icon: "braces.svg" },
        { value: "color", label: "Colors", icon: "palette.svg" }
    ]
    property string activeFilter: "all"
    readonly property bool pinnedTab: activeFilter === "pinned"
    readonly property Item activeList: pinnedTab ? favoritesList : historyList
    property string appliedQuery: ""
    property string historySelection: ""
    property string favoritesSelection: ""
    property real historyScroll: 0
    property real favoritesScroll: 0
    property bool clearConfirmationOpen: false
    property bool deleteConfirmationOpen: false
    property string confirmationError: ""
    property string pendingFavoriteKey: ""
    property bool deletePending: false
    readonly property bool confirmationOpen: clearConfirmationOpen || deleteConfirmationOpen
    readonly property bool busy: ClipboardService.clearingHistory || deletePending

    function switchFilter(value) {
        if (busy || value === activeFilter)
            return;
        const wasPinned = pinnedTab;
        closeConfirmation();
        if (wasPinned) {
            favoritesScroll = favoritesList.listView.contentY;
            favoritesSelection = favoritesList.selectedKey;
        } else {
            historyScroll = historyList.listView.contentY;
            historySelection = historyList.selectedKey;
        }
        activeFilter = value;
        Qt.callLater(() => {
            if (wasPinned !== root.pinnedTab)
                root.activeList.listView.contentY = root.pinnedTab ? root.favoritesScroll : root.historyScroll;
            root.activeList.restoreSelection();
        });
    }

    function cycleFilter(offset) {
        const index = filters.findIndex(filter => filter.value === activeFilter);
        switchFilter(filters[(index + offset + filters.length) % filters.length].value);
    }

    function copyAndClose(key) {
        if (key.length > 0)
            ClipboardService.copyEntry(key, true);
    }

    function requestClear() {
        if (busy)
            return;
        deleteConfirmationOpen = false;
        pendingFavoriteKey = "";
        confirmationError = "";
        clearConfirmationOpen = true;
    }

    function requestFavoriteDelete(key) {
        if (busy)
            return;
        clearConfirmationOpen = false;
        pendingFavoriteKey = key;
        confirmationError = "";
        deleteConfirmationOpen = true;
    }

    function closeConfirmation() {
        if (busy)
            return;
        clearConfirmationOpen = false;
        deleteConfirmationOpen = false;
        confirmationError = "";
        pendingFavoriteKey = "";
        searchField.forceActiveFocus();
    }

    function confirm() {
        if (busy)
            return;
        if (deleteConfirmationOpen) {
            if (pendingFavoriteKey.length === 0)
                return;
            deletePending = true;
            ClipboardService.controller.deleteFavoriteEntry(pendingFavoriteKey);
        } else if (!pinnedTab) {
            ClipboardService.controller.clearHistory();
        } else if (ClipboardService.controller.clearFavorites()) {
            closeConfirmation();
        } else {
            confirmationError = ClipboardService.errorMessage;
        }
    }

    Component.onCompleted: {
        ClipboardService.acquireList();
        searchField.forceActiveFocus();
    }
    Component.onDestruction: ClipboardService.releaseList()

    Keys.onEscapePressed: {
        if (root.confirmationOpen)
            root.closeConfirmation();
        else
            IslandController.reset();
    }

    Connections {
        target: ClipboardService
        function onCopyFinished(key, success, dismissed) {
            if (dismissed)
                IslandController.reset();
        }
    }

    Connections {
        target: ClipboardService.controller
        function onHistoryClearCompleted(success, errorText) {
            if (success)
                root.closeConfirmation();
            else
                root.confirmationError = errorText;
        }
        function onEntryDeleteCompleted(key, favorite, success, errorText) {
            if (!favorite || key !== root.pendingFavoriteKey)
                return;
            root.deletePending = false;
            if (success)
                root.closeConfirmation();
            else
                root.confirmationError = errorText;
        }
    }

    Timer {
        id: searchDelay
        interval: 150
        onTriggered: root.appliedQuery = searchField.text
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        PanelHeader {
            Layout.fillWidth: true
            title: "Clipboard"
            trailingText: root.pinnedTab ? "Clear pinned" : "Clear history"
            trailingClickable: !root.busy
            scrollTargets: [root.activeList.listView]
            onBack: IslandController.openNavigation()
            onTrailingClicked: root.requestClear()
        }

        SearchField {
            id: searchField
            objectName: "clipboard-search"
            Layout.fillWidth: true
            placeholderText: "Search clipboard…"
            onTextChanged: searchDelay.restart()
            onNavigateDown: root.activeList.selectRelative(1)
            Keys.onUpPressed: root.activeList.selectRelative(-1)
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    root.cycleFilter(event.key === Qt.Key_Backtab ? -1 : 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) {
                    root.activeList.selectRelative(event.key === Qt.Key_PageUp ? -8 : 8);
                    event.accepted = true;
                }
            }
            onAccepted: {
                searchDelay.stop();
                root.appliedQuery = text;
                root.activeList.copySelected();
            }
        }

        Flow {
            objectName: "clipboard-filters"
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: root.filters

                Button {
                    id: chip
                    required property var modelData
                    readonly property bool selected: root.activeFilter === modelData.value
                    objectName: "clipboard-filter-" + modelData.value
                    implicitHeight: 30
                    leftPadding: 10
                    rightPadding: 12
                    hoverEnabled: true
                    focusPolicy: Qt.NoFocus
                    enabled: !root.busy
                    onClicked: root.switchFilter(modelData.value)

                    HoverHandler {
                        enabled: chip.enabled
                        cursorShape: Qt.PointingHandCursor
                    }

                    contentItem: Row {
                        spacing: 6
                        SvgIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            source: "../assets/icons/" + chip.modelData.icon
                            size: 14
                            color: chip.selected ? Theme.background : Theme.textSecondary
                        }
                        UiText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: chip.modelData.label
                            color: chip.selected ? Theme.background : Theme.textPrimary
                            font.pixelSize: 12
                        }
                    }

                    background: Rectangle {
                        radius: height / 2
                        color: chip.selected ? Theme.accent
                            : chip.down ? Theme.buttonPressed : chip.hovered ? Theme.surfaceVariant : Theme.surface
                        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
                    }
                }
            }
        }

        UiText {
            objectName: "clipboard-error"
            Layout.fillWidth: true
            visible: ClipboardService.errorMessage.length > 0
            text: ClipboardService.errorMessage
            color: Theme.danger
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        UiText {
            Layout.fillWidth: true
            visible: root.pinnedTab && searchField.text.trim().length > 0
            text: "Clear search to reorder pinned entries."
            color: Theme.textMuted
            font.pixelSize: 11
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            Item {
                Layout.preferredWidth: (content.width - 14 * 2 - 1) * 0.48
                Layout.fillHeight: true
                clip: true

                ClipboardEntryList {
                    id: historyList
                    anchors.fill: parent
                    visible: !root.pinnedTab
                    favorites: false
                    sourceModel: ClipboardService.controller.historyModel
                    query: root.appliedQuery
                    searchText: searchField.text
                    kindFilter: root.activeFilter === "all" || root.pinnedTab ? "" : root.activeFilter
                    selectedKey: root.historySelection
                    onSelectedKeyChanged: if (!root.pinnedTab) root.historySelection = selectedKey
                    onCopyRequested: key => root.copyAndClose(key)
                }

                ClipboardEntryList {
                    id: favoritesList
                    anchors.fill: parent
                    visible: root.pinnedTab
                    favorites: true
                    sourceModel: ClipboardService.controller.favoritesModel
                    query: root.appliedQuery
                    searchText: searchField.text
                    selectedKey: root.favoritesSelection
                    onSelectedKeyChanged: if (root.pinnedTab) root.favoritesSelection = selectedKey
                    onCopyRequested: key => root.copyAndClose(key)
                    onDeleteFavoriteRequested: key => root.requestFavoriteDelete(key)
                }
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: Theme.border
            }

            ClipboardPreview {
                objectName: "clipboard-preview"
                Layout.fillWidth: true
                Layout.fillHeight: true
                entry: root.activeList.selectedEntry
            }
        }

        UiText {
            objectName: "clipboard-footer"
            Layout.fillWidth: true
            text: root.activeList.count + " items    ↑ ↓ Select    Enter Copy & close    Double-click Copy    Tab Filter    Esc Close"
            color: Theme.textMuted
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }

    // Confirmation for clearing history/pins or deleting a pinned entry.
    Rectangle {
        objectName: "clipboard-confirmation"
        anchors.fill: parent
        radius: 30
        color: Theme.overlayStrong
        visible: opacity > 0
        opacity: root.confirmationOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animationFast } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeConfirmation()
        }

        Rectangle {
            anchors.centerIn: parent
            width: 420
            height: confirmContent.implicitHeight + 40
            radius: 24
            color: Theme.background
            border.width: 1
            border.color: Theme.border

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: confirmContent
                anchors.fill: parent
                anchors.margins: 20
                spacing: 8

                UiText {
                    Layout.fillWidth: true
                    text: root.deleteConfirmationOpen ? "Delete pinned entry and history entries?"
                        : root.pinnedTab ? "Remove all pinned entries?" : "Clear clipboard history?"
                    color: Theme.textPrimary
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }

                UiText {
                    Layout.fillWidth: true
                    text: root.deleteConfirmationOpen
                        ? "This removes the pinned entry and permanently deletes all matching history entries."
                        : root.pinnedTab ? "This removes every pinned entry and its stored payload."
                        : "This permanently removes every item from cliphist."
                    color: Theme.textSecondary
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                UiText {
                    Layout.fillWidth: true
                    visible: root.confirmationError.length > 0
                    text: root.confirmationError
                    color: Theme.danger
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    spacing: 8

                    Item { Layout.fillWidth: true }

                    TextActionButton {
                        objectName: "clipboard-confirm-cancel"
                        text: "Cancel"
                        enabled: !root.busy
                        onClicked: root.closeConfirmation()
                    }

                    TextActionButton {
                        id: confirmButton
                        objectName: "clipboard-confirm-accept"
                        danger: true
                        enabled: !root.busy
                        text: root.busy ? (root.deleteConfirmationOpen ? "Deleting…" : "Clearing…")
                            : root.deleteConfirmationOpen ? "Delete entry"
                            : root.pinnedTab ? "Clear pinned" : "Clear history"
                        onClicked: root.confirm()
                        Keys.onReturnPressed: root.confirm()
                        Keys.onEnterPressed: root.confirm()
                    }
                }
            }
        }
    }

    onConfirmationOpenChanged: if (confirmationOpen) confirmButton.forceActiveFocus()
}
