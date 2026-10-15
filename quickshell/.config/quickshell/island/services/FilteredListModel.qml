import QtQuick

QtObject {
    id: root
    property var sourceModel: null
    property string searchText: ""
    property var roles: []
    property var searchRoles: []
    property bool searchFileNames: false
    property int maximumCount: 0
    // Optional function(row) -> bool that drops rows, and function(a, b) -> number that orders the rest
    // (ties keep source order). Both read outside state, so callers rebuild when that state changes.
    property var filter: null
    property var comparator: null
    readonly property ListModel model: ListModel {}
    signal rebuilt(bool resetSelection)

    function matches(row, query) {
        return searchRoles.some(role => {
            const value = searchFileNames ? String(row[role]).split("/").pop() : String(row[role]);
            return value.replace(/[-_]/g, " ").toLowerCase().includes(query);
        });
    }

    function filteredRows() {
        const rows = [];
        if (!sourceModel) return rows;
        const query = searchText.trim().replace(/[-_]/g, " ").toLowerCase();
        for (let index = 0; index < sourceModel.count; index++) {
            const source = sourceModel.get(index);
            if (query && !matches(source, query)) continue;
            const row = {};
            for (const role of roles) row[role] = source[role];
            if (filter && !filter(row)) continue;
            rows.push(row);
            if (maximumCount > 0 && !comparator && rows.length >= maximumCount) break;
        }
        if (comparator) {
            rows.sort(comparator);
            if (maximumCount > 0) rows.length = Math.min(rows.length, maximumCount);
        }
        return rows;
    }

    function updateRows(rows) {
        for (let index = 0; index < rows.length; index++) {
            const row = rows[index];
            if (index >= model.count) model.append(row);
            else {
                for (const role of roles) {
                    if (model.get(index)[role] !== row[role])
                        model.setProperty(index, role, row[role]);
                }
            }
        }
        if (model.count > rows.length)
            model.remove(rows.length, model.count - rows.length);
    }

    function rebuild(resetSelection) {
        updateRows(filteredRows());
        rebuilt(resetSelection);
    }

    onSourceModelChanged: rebuild(true)
    onSearchTextChanged: rebuild(true)
    onMaximumCountChanged: rebuild(true)
    onFilterChanged: rebuild(false)
    onComparatorChanged: rebuild(false)
    Component.onCompleted: rebuild(true)
    readonly property Connections sourceChanges: Connections {
        target: root.sourceModel
        function onRowsInserted() { root.rebuild(false); }
        function onRowsRemoved() { root.rebuild(false); }
        function onRowsMoved() { root.rebuild(false); }
        function onDataChanged() { root.rebuild(false); }
        function onModelReset() { root.rebuild(false); }
    }
}
