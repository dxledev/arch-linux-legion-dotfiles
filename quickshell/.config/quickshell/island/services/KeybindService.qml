pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string helper: Quickshell.env("ISLAND_KEYBINDS_SCRIPT")
        || Qt.resolvedUrl("../integration/keybinds").toString().replace(/^file:\/\//, "")
    property var entries: []
    property string error: ""
    readonly property bool loading: reader.running
    readonly property bool busy: writer.running

    signal actionFinished(bool succeeded, string message)

    function refresh() {
        if (loading || busy)
            return
        error = ""
        reader.running = true
    }

    function filteredEntries(query) {
        const terms = String(query || "").trim().toLowerCase().split(/\s+/).filter(term => term.length > 0)
        return entries.filter(entry => terms.every(term =>
            [entry.description, entry.shortcut].join(" ").toLowerCase().includes(term)))
    }

    function execute(entry) {
        if (busy || loading || !entry || !entries.some(candidate => candidate.id === entry.id))
            return false
        error = ""
        writer.command = [helper, "run", entry.id]
        writer.running = true
        return true
    }

    function loadEntries() {
        try {
            const result = JSON.parse(listOutput.text)
            if (!Array.isArray(result) || !result.every(entry => typeof entry.id === "string"
                    && typeof entry.description === "string" && typeof entry.shortcut === "string"))
                throw new Error("The keybind list is invalid.")
            entries = result.map(entry => Object.assign({}, entry, {
                description: entry.description === "Project Lyrics to Island" ? entry.description
                    : entry.description.replace(/\bIsland\b/gi, "").replace(/\s+/g, " ").trim()
            })).filter(entry => entry.description.length > 0)
        } catch (exception) {
            entries = []
            error = String(exception)
        }
    }

    Process {
        id: reader
        command: ["/usr/bin/timeout", "10s", root.helper, "list"]
        stdout: StdioCollector { id: listOutput }
        stderr: StdioCollector { id: listError }
        onExited: function(code) {
            if (code === 0)
                root.loadEntries()
            else {
                root.entries = []
                root.error = listError.text.trim() || "Could not load Hyprland keybinds."
            }
        }
    }

    Process {
        id: writer
        stdout: StdioCollector {}
        stderr: StdioCollector { id: actionError }
        onExited: function(code) {
            root.error = code === 0 ? "" : actionError.text.trim() || "Could not run the keybind."
            root.actionFinished(code === 0, root.error)
        }
    }
}
