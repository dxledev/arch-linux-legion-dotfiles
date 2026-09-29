.pragma library

function canReorder(query) {
    return String(query).trim().length === 0;
}

function begin(state, key) {
    state.draggingKey = key;
    state.insertionKey = "";
    state.dropAtEnd = false;
}

function setInsertion(state, key, atEnd) {
    state.insertionKey = key;
    state.dropAtEnd = atEnd;
}

function cancel(state) {
    state.draggingKey = "";
    state.insertionKey = "";
    state.dropAtEnd = false;
}

function drop(state, controller, sourceKey, beforeKey) {
    if (sourceKey && sourceKey !== beforeKey)
        controller.moveFavorite(sourceKey, beforeKey);
    cancel(state);
}

function finish(state, controller) {
    const hasTarget = state.insertionKey.length > 0 || state.dropAtEnd;
    if (hasTarget)
        drop(state, controller, state.draggingKey, state.dropAtEnd ? "" : state.insertionKey);
    else
        cancel(state);
}
