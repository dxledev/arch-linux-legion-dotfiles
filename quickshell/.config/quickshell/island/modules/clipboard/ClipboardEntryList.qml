pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Shell.Clipboard
import "../../components"
import "../../styles"
import "ClipboardFormat.js" as ClipboardFormat

Item {
    id: root

    required property var sourceModel
    required property bool favorites
    required property string query
    required property string searchText
    property string kindFilter: ""
    property var selectedEntry: ({})
    property string selectedKey: ""
    property string selectedHash: ""
    property bool refreshing: false
    property real refreshScroll: 0
    property string insertionKey: ""
    property bool dropAtEnd: false
    property string draggingKey: ""
    property bool dragCancelled: false
    property point dragPoint: Qt.point(0, 0)
    readonly property int count: filterModel.count
    readonly property alias listView: list
    readonly property bool dragActive: draggingKey.length > 0
    readonly property var controller: ClipboardService.controller
    readonly property bool initialLoading: ClipboardService.loading && !ClipboardService.historyRefreshCompleted

    signal copyRequested(string key)
    signal deleteFavoriteRequested(string key)

    function refreshPreview() {
        if (refreshing)
            return;
        selectedEntry = filterModel.entryAt(list.currentIndex);
        const key = selectedEntry.key || "";
        selectedKey = key;
        selectedHash = selectedEntry.contentHash || "";
        if (!favorites && key.length > 0)
            controller.prioritizeHistory([key]);
    }

    function selectIndex(index) {
        list.currentIndex = index;
        const wasRefreshing = refreshing;
        refreshing = false;
        refreshPreview();
        refreshing = wasRefreshing;
        refreshScroll = list.contentY;
    }

    function copySelected() {
        const key = filterModel.keyAt(list.currentIndex);
        if (key.length > 0)
            root.copyRequested(key);
    }

    function selectRelative(offset) {
        if (list.count === 0)
            return;
        const next = list.currentIndex < 0 ? 0 : Math.max(0, Math.min(list.count - 1, list.currentIndex + offset));
        selectIndex(next);
        list.positionViewAtIndex(next, ListView.Contain);
        refreshScroll = list.contentY;
    }

    function selectionIndex() {
        for (let row = 0; row < filterModel.count; row++) {
            if (filterModel.keyAt(row) === selectedKey)
                return row;
        }
        if (selectedHash.length > 0) {
            for (let row = 0; row < filterModel.count; row++) {
                if (filterModel.entryAt(row).contentHash === selectedHash)
                    return row;
            }
        }
        return filterModel.count > 0 ? 0 : -1;
    }

    function restoreSelection() {
        if (refreshing)
            return;
        list.currentIndex = selectionIndex();
        refreshPreview();
    }

    function finishRefresh() {
        if (!refreshing || controller.loading)
            return;
        list.forceLayout();
        list.currentIndex = selectionIndex();
        list.forceLayout();
        refreshing = false;
        refreshPreview();
        list.contentY = Math.max(list.originY, Math.min(refreshScroll, list.originY + Math.max(0, list.contentHeight - list.height)));
    }

    // Decode the rows around the viewport first so thumbnails and kinds appear where the user is looking.
    function prioritizeVisible() {
        if (favorites || filterModel.count === 0)
            return;
        const center = list.indexAt(list.width / 2, list.contentY + list.height / 2);
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

    function beginDrag(key) {
        draggingKey = key;
        insertionKey = "";
        dropAtEnd = false;
    }

    function cancelDrag() {
        draggingKey = "";
        insertionKey = "";
        dropAtEnd = false;
    }

    function finishDrag() {
        if (insertionKey.length > 0 || dropAtEnd) {
            const beforeKey = dropAtEnd ? "" : insertionKey;
            if (draggingKey && draggingKey !== beforeKey)
                controller.moveFavorite(draggingKey, beforeKey);
        }
        cancelDrag();
    }

    function updateDropTarget(position) {
        if (!dragActive || !ClipboardFormat.canReorder(searchText))
            return;

        const rows = [];
        for (const item of list.contentItem.children) {
            if (item && typeof item.entryKey === "string" && item.visible)
                rows.push({ item: item, y: item.mapToItem(list, 0, 0).y });
        }
        rows.sort((left, right) => left.y - right.y);
        for (const row of rows) {
            if (position.y < row.y + row.item.height / 2) {
                insertionKey = row.item.entryKey;
                dropAtEnd = false;
                return;
            }
        }

        if (rows.length === 0) {
            insertionKey = "";
            dropAtEnd = false;
            return;
        }
        const nextIndex = rows[rows.length - 1].item.index + 1;
        insertionKey = nextIndex < filterModel.count ? filterModel.keyAt(nextIndex) : "";
        dropAtEnd = nextIndex >= filterModel.count;
    }

    ClipboardFilterModel {
        id: filterModel
        sourceModel: root.sourceModel
        query: root.query
        kind: root.kindFilter
    }

    ListView {
        id: list
        objectName: root.favorites ? "clipboard-pinned-list" : "clipboard-history-list"
        anchors.fill: parent
        clip: true
        spacing: 6
        model: filterModel
        currentIndex: -1
        boundsBehavior: Flickable.StopAtBounds
        reuseItems: true
        SmoothScroll { scrollTarget: list }
        ScrollBar.vertical: ScrollBar {}

        delegate: ClipboardEntryRow {
            required property string key
            required property string previewText
            required property string payloadKind
            required property string mimeType
            required property double size
            required property string thumbnailUrl
            required property bool favorite
            required property bool loading
            required property string errorText
            required property int index

            width: list.width - 10
            entryKey: key
            preview: previewText
            kind: payloadKind
            mime: mimeType
            byteSize: size
            thumbnail: thumbnailUrl
            isFavorite: favorite
            isLoading: loading
            error: errorText
            favoritesTab: root.favorites
            dragEnabled: root.favorites && ClipboardFormat.canReorder(root.searchText)
            selected: list.currentIndex === index
            insertionBefore: root.dragActive && root.insertionKey === key
            deleteEnabled: !ClipboardService.deleting

            onSelectRequested: root.selectIndex(index)
            onCopyRequested: {
                root.selectIndex(index);
                root.copyRequested(entryKey);
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
                root.beginDrag(key);
            }
            onDragMoved: position => {
                root.dragPoint = position;
                root.updateDropTarget(position);
            }
            onDragEnded: Qt.callLater(() => {
                if (root.dragCancelled)
                    root.cancelDrag();
                else
                    root.finishDrag();
                root.dragCancelled = false;
            })
            onDragCancelled: {
                root.dragCancelled = true;
                root.cancelDrag();
            }
        }

        footer: Item {
            width: list.width
            height: visible ? 16 : 0
            visible: root.favorites && root.query.trim().length === 0 && list.count > 0

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 10
                anchors.rightMargin: 20
                height: 2
                radius: 1
                color: Theme.accent
                visible: root.dragActive && root.dropAtEnd
            }
        }

        onCurrentIndexChanged: root.refreshPreview()
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

    // Auto-scroll while dragging a pinned entry near the list edges.
    Timer {
        interval: 45
        repeat: true
        running: root.dragActive
        onTriggered: {
            if (root.dragPoint.y < 38)
                list.contentY = Math.max(0, list.contentY - 24);
            else if (root.dragPoint.y > list.height - 38)
                list.contentY = Math.max(0, Math.min(list.contentHeight - list.height, list.contentY + 24));
        }
    }

    UiText {
        objectName: root.favorites ? "clipboard-pinned-empty" : "clipboard-history-empty"
        anchors.centerIn: parent
        width: parent.width - 40
        visible: filterModel.count === 0
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: Theme.textMuted
        font.pixelSize: 13
        text: {
            const searching = root.query.trim().length > 0;
            const failed = ClipboardService.errorMessage.length > 0;
            if (searching && (root.sourceModel.processing || root.initialLoading))
                return "Searching clipboard entries…";
            if (searching && failed)
                return "Clipboard search is unavailable.";
            if (searching || root.kindFilter.length > 0)
                return "No matching clipboard entries.";
            if (root.sourceModel.processing || (root.initialLoading && root.sourceModel.count === 0))
                return root.favorites ? "Loading pinned entries…" : "Loading clipboard history…";
            if (failed)
                return root.favorites ? "Pinned entries are unavailable." : "Clipboard history is unavailable.";
            return root.favorites ? "No pinned entries yet. Star a history entry to keep it here."
                : "No clipboard history yet.";
        }
    }

    Connections {
        target: filterModel
        function onDataChanged() {
            root.refreshPreview();
        }
        function onRowsMoved() {
            Qt.callLater(root.restoreSelection);
        }
        function onCountChanged() {
            Qt.callLater(() => {
                root.restoreSelection();
                root.prioritizeVisible();
            });
        }
    }

    Connections {
        target: ClipboardService.controller
        function onLoadingChanged() {
            if (root.favorites)
                return;
            if (ClipboardService.controller.loading) {
                if (!root.refreshing)
                    root.refreshScroll = list.contentY;
                root.refreshing = root.selectedKey.length > 0;
            } else if (root.refreshing) {
                Qt.callLater(root.finishRefresh);
            }
        }
    }
}
