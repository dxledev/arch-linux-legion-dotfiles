pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import Shell.Clipboard
import "FavoriteReorder.js" as FavoriteReorder

Item {
    id: root

    required property var sourceModel
    required property var controller
    required property bool favorites
    required property string query
    required property string searchText
    property string selectedKey: ""
    property string insertionKey: ""
    property bool dropAtEnd: false
    property string draggingKey: ""
    property bool dragCancelled: false
    property point dragPoint: Qt.point(0, 0)
    readonly property alias listView: list
    readonly property bool dragActive: draggingKey.length > 0

    signal deleteFavoriteRequested(string key)

    function copySelected(): void {
        const key = filterModel.keyAt(list.currentIndex);
        if (key.length > 0)
            controller.copyEntry(key);
    }

    function selectRelative(offset: int): void {
        if (list.count === 0)
            return;
        const next = list.currentIndex < 0 ? 0 : Math.max(0, Math.min(list.count - 1, list.currentIndex + offset));
        list.currentIndex = next;
        list.positionViewAtIndex(next, ListView.Contain);
        selectedKey = filterModel.keyAt(next);
    }

    function restoreSelection(): void {
        if (!selectedKey.length)
            return;
        for (let row = 0; row < filterModel.count; row++) {
            if (filterModel.keyAt(row) === selectedKey) {
                list.currentIndex = row;
                return;
            }
        }
        list.currentIndex = filterModel.count > 0 ? 0 : -1;
        if (filterModel.count > 0)
            selectedKey = filterModel.keyAt(0);
    }

    function prioritizeVisible(): void {
        if (favorites || filterModel.count === 0)
            return;
        const center = list.indexAt(list.width / 2, list.height / 2);
        if (center < 0)
            return;
        const keys = [];
        for (let row = Math.max(0, center - 8); row < Math.min(filterModel.count, center + 9); row++) {
            const key = filterModel.keyAt(row);
            if (key.length > 0)
                keys.push(key);
        }
        controller.prioritizeHistory(keys);
    }

    function updateDropTarget(position: point): void {
        if (!dragActive || !FavoriteReorder.canReorder(searchText))
            return;

        const rows = [];
        for (const item of list.contentItem.children) {
            if (item && typeof item.entryKey === "string" && item.visible)
                rows.push({item: item, y: item.mapToItem(list, 0, 0).y});
        }
        rows.sort((left, right) => left.y - right.y);
        for (const row of rows) {
            if (position.y < row.y + row.item.height / 2) {
                FavoriteReorder.setInsertion(root, row.item.entryKey, false);
                return;
            }
        }

        if (rows.length === 0) {
            FavoriteReorder.setInsertion(root, "", false);
            return;
        }
        const last = rows[rows.length - 1].item;
        const nextIndex = last.index + 1;
        FavoriteReorder.setInsertion(root, nextIndex < filterModel.count ? filterModel.keyAt(nextIndex) : "", nextIndex >= filterModel.count);
    }

    ClipboardFilterModel {
        id: filterModel
        sourceModel: root.sourceModel
        query: root.query
    }

    ListView {
        id: list

        anchors.fill: parent
        clip: true
        spacing: Tokens.spacing.small
        model: filterModel
        currentIndex: -1
        boundsBehavior: Flickable.StopAtBounds
        reuseItems: true
        delegate: EntryRow {
            required property string key
            required property string previewText
            required property string searchableText
            required property string payloadKind
            required property string mimeType
            required property double size
            required property string thumbnailUrl
            required property bool favorite
            required property bool loading
            required property string errorText
            required property int index

            width: list.width
            entryKey: key
            preview: previewText
            searchable: searchableText
            kind: payloadKind
            mime: mimeType
            byteSize: size
            thumbnail: thumbnailUrl
            isFavorite: favorite
            isLoading: loading
            error: errorText
            favoritesTab: root.favorites
            dragEnabled: root.favorites && FavoriteReorder.canReorder(root.searchText)
            selected: list.currentIndex === index
            insertionBefore: root.insertionKey === key
            controller: root.controller

            onCopyRequested: {
                list.currentIndex = index;
                root.controller.copyEntry(entryKey);
            }
            onFavoriteRequested: enabled => root.controller.setFavorite(entryKey, enabled)
            onDeleteRequested: {
                if (root.favorites)
                    root.deleteFavoriteRequested(entryKey);
                else
                    root.controller.deleteHistoryEntry(entryKey);
            }
            onDragStarted: key => {
                root.dragCancelled = false;
                FavoriteReorder.begin(root, key);
            }
            onDragMoved: position => {
                root.dragPoint = position;
                root.updateDropTarget(position);
            }
            onDragEnded: Qt.callLater(() => {
                if (root.dragCancelled)
                    FavoriteReorder.cancel(root);
                else
                    FavoriteReorder.finish(root, root.controller);
                root.dragCancelled = false;
            })
            onDragCancelled: {
                root.dragCancelled = true;
                FavoriteReorder.cancel(root);
            }
        }

        footer: Item {
            width: list.width
            height: visible ? 28 : 0
            visible: root.favorites && root.query.trim().length === 0 && list.count > 0

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 2
                color: Style.accent
                visible: root.dragActive && root.dropAtEnd
            }
        }

        onCurrentIndexChanged: {
            const key = filterModel.keyAt(currentIndex);
            if (key.length > 0)
                root.selectedKey = key;
        }
        onContentYChanged: {
            priorityDelay.restart();
            if (root.dragActive)
                root.updateDropTarget(root.dragPoint);
        }
        onHeightChanged: priorityDelay.restart()
        onCountChanged: Qt.callLater(root.restoreSelection)

        Timer {
            id: priorityDelay
            interval: 30
            onTriggered: root.prioritizeVisible()
        }
    }

    Timer {
        interval: 45
        repeat: true
        running: root.dragActive
        onTriggered: {
            if (root.dragPoint.y < 38)
                list.contentY = Math.max(0, list.contentY - 24);
            else if (root.dragPoint.y > list.height - 38)
                list.contentY = Math.min(list.contentHeight - list.height, list.contentY + 24);
        }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - Tokens.padding.large * 2
        spacing: Tokens.spacing.small
        visible: filterModel.count === 0

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: Style.muted
            font: Tokens.font.body.medium
            text: root.query.trim().length > 0 && (root.sourceModel.processing || ClipboardState.controller.loading) ? "Searching clipboard entries…"
                : root.query.trim().length > 0 && ClipboardState.controller.errorMessage.length > 0 ? "Clipboard search is unavailable."
                : root.query.trim().length > 0 ? "No matching clipboard entries."
                : root.sourceModel.processing ? (root.favorites ? "Loading favorites…" : "Loading clipboard entries…")
                : ClipboardState.controller.loading && root.sourceModel.count === 0 ? (root.favorites ? "Loading favorites…" : "Loading clipboard history…")
                : ClipboardState.controller.errorMessage.length > 0 ? (root.favorites ? "Favorites are unavailable." : "Clipboard history is unavailable.")
                : root.favorites ? "No favorites yet. Star a history entry to keep it here."
                : ClipboardState.controller.loading ? "Loading clipboard history…"
                : "No clipboard history yet."
        }
    }

    Connections {
        target: filterModel
        function onCountChanged(): void {
            Qt.callLater(() => {
                root.restoreSelection();
                root.prioritizeVisible();
            });
        }
    }

    Connections {
        target: ClipboardState.controller
        function onLoadingChanged(): void {
            if (!root.favorites && ClipboardState.controller.loading)
                root.selectedKey = filterModel.keyAt(list.currentIndex) || root.selectedKey;
        }
    }
}
