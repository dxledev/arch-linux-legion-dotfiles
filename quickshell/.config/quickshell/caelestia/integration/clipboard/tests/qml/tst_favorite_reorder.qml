import QtQuick
import QtTest
import Shell.Clipboard 1.0
import "../../../../modules/clipboard/FavoriteReorder.js" as FavoriteReorder

TestCase {
    name: "ClipboardFavoriteReorder"

    function newState() {
        return {draggingKey: "", insertionKey: "", dropAtEnd: false};
    }

    function test_filteredSearchDisablesReordering() {
        verify(FavoriteReorder.canReorder(""));
        verify(FavoriteReorder.canReorder("   "));
        verify(!FavoriteReorder.canReorder("invoice"));
    }

    function test_cancelKeepsOrderUnchanged() {
        const state = newState();
        const calls = [];
        const controller = {moveFavorite: (key, beforeKey) => calls.push([key, beforeKey])};

        FavoriteReorder.begin(state, "first");
        FavoriteReorder.setInsertion(state, "second", false);
        FavoriteReorder.cancel(state);

        compare(state.draggingKey, "");
        compare(state.insertionKey, "");
        verify(!state.dropAtEnd);
        compare(calls.length, 0);
    }

    function test_dropPersistsOneReorder() {
        const state = newState();
        const calls = [];
        const controller = {moveFavorite: (key, beforeKey) => calls.push([key, beforeKey])};

        FavoriteReorder.begin(state, "first");
        FavoriteReorder.setInsertion(state, "third", false);
        FavoriteReorder.finish(state, controller);

        compare(calls.length, 1);
        compare(calls[0][0], "first");
        compare(calls[0][1], "third");
        compare(state.draggingKey, "");
        compare(state.insertionKey, "");
    }

    function test_dropAtEndAndSelfDrop() {
        const state = newState();
        const calls = [];
        const controller = {moveFavorite: (key, beforeKey) => calls.push([key, beforeKey])};

        FavoriteReorder.begin(state, "last");
        FavoriteReorder.setInsertion(state, "", true);
        FavoriteReorder.finish(state, controller);
        compare(calls.length, 1);
        compare(calls[0][1], "");

        FavoriteReorder.begin(state, "last");
        FavoriteReorder.drop(state, controller, "last", "last");
        compare(calls.length, 1);
    }

    function test_nativeFilterModelImportAndCount() {
        const model = Qt.createQmlObject("import QtQuick; import Shell.Clipboard 1.0; ClipboardFilterModel {}", this);
        verify(model !== null);
        compare(model.count, 0);
        model.destroy();
    }
}
