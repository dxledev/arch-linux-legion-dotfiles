import Quickshell.Io

FileView {
    id: root
    required property var modelData
    required property string directory
    property bool initialized: false
    property string lastEvent: ""
    signal received(string event)
    path: directory + "/brightness/" + modelData.name
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
        const event = text().trim();
        if (initialized && event !== lastEvent) root.received(event);
        lastEvent = event;
        initialized = true;
    }
    onLoadFailed: initialized = true
}
