pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../island"
import "WorkspacePresentation.js" as Presentation

Singleton {
    id: root

    readonly property string helper: Quickshell.env("ISLAND_WORKSPACE_PRESENTATION_SCRIPT")
        || Quickshell.shellDir + "/integration/workspace-presentation"
    readonly property int pollInterval: {
        const configured = Number(Quickshell.env("ISLAND_WORKSPACE_PRESENTATION_POLL_MS"))
        return Number.isFinite(configured) && configured > 0
            ? Math.max(250, Math.min(5000, Math.round(configured))) : 1000
    }
    readonly property var layouts: [
        "dwindle", "scrolling", "master", "monocle",
        "lua:grid", "lua:spiral", "lua:manual", "lua:centerstack"
    ]
    property bool statusKnown: false
    property string mode: ""
    property string layout: ""
    property string axis: ""
    property string effectiveAxis: ""
    property bool reportedAxisLocked: false
    property bool refreshPending: false
    property bool actionPending: false
    property string pendingOperation: ""
    property string pendingValue: ""
    property string activeOperation: ""
    property string error: ""

    readonly property bool loading: reader.running
    readonly property bool axisLocked: reportedAxisLocked || isScrollingLayout(layout)
    readonly property bool canOpenAxis: Presentation.canOpenAxis(statusKnown, layout, reportedAxisLocked, effectiveAxis)

    signal statusRefreshed(bool succeeded)
    signal actionFinished(string operation, bool succeeded, string message)

    function isValidAxis(value) {
        return Presentation.isAxis(value)
    }

    function isScrollingLayout(value) {
        return Presentation.isScrollingLayout(value)
    }

    function normalizeLayout(value) {
        return Presentation.normalizeLayout(value)
    }

    function refresh() {
        // The helper reads Hyprland's layout and animation settings; there is nothing to read under niri.
        if (Compositor.niri) return
        if (reader.running) {
            refreshPending = true
            return
        }
        error = ""
        reader.command = [helper, "status", "island"]
        reader.running = true
    }

    function requestAction(operation, value) {
        if (!Presentation.canStartAction(actionPending, writer.running, operation, value, layouts))
            return false
        actionPending = true
        pendingOperation = operation
        pendingValue = value
        error = ""
        refresh()
        return true
    }

    function setAxis(value) {
        return requestAction("axis", value)
    }

    function setLayout(value) {
        return requestAction("layout", value)
    }

    function finishStatus(succeeded) {
        if (refreshPending) {
            refreshPending = false
            Qt.callLater(refresh)
            return
        }
        statusRefreshed(succeeded)
        if (!Presentation.shouldStartAction(actionPending, pendingOperation, writer.running))
            return
        if (!succeeded) {
            finishAction(false, error || "Workspace presentation status is unavailable.")
            return
        }
        if (pendingOperation === "axis" && !canOpenAxis) {
            finishAction(false, "Workspace Axis is unavailable while the Scrolling layout is active.")
            return
        }
        activeOperation = pendingOperation
        writer.command = [helper, "set-" + pendingOperation, "island", pendingValue]
        pendingOperation = ""
        pendingValue = ""
        writer.running = true
    }

    function finishAction(succeeded, message) {
        const operation = activeOperation || pendingOperation
        actionPending = false
        activeOperation = ""
        pendingOperation = ""
        pendingValue = ""
        error = succeeded ? "" : message
        if (succeeded)
            statusKnown = false
        actionFinished(operation, succeeded, error)
        if (succeeded)
            Qt.callLater(refresh)
    }

    function loadStatus() {
        try {
            const data = JSON.parse(statusOutput.text)
            const nextLayout = normalizeLayout(data.layout)
            if (data.mode !== "island" || !Presentation.isSupportedLayout(nextLayout, layouts)
                    || !isValidAxis(data.axis) || !isValidAxis(data.effectiveAxis)
                    || typeof data.axisLocked !== "boolean")
                throw new Error("Workspace presentation status is incomplete.")
            mode = String(data.mode || "")
            layout = nextLayout
            axis = data.axis
            effectiveAxis = data.effectiveAxis
            reportedAxisLocked = data.axisLocked
            statusKnown = true
            error = ""
            return true
        } catch (exception) {
            statusKnown = false
            reportedAxisLocked = false
            error = String(exception)
            return false
        }
    }

    function refreshIfIdle() {
        if (!reader.running && !writer.running && !actionPending)
            refresh()
    }

    Process {
        id: reader
        command: [root.helper, "status", "island"]
        stdout: StdioCollector { id: statusOutput }
        stderr: StdioCollector { id: statusError }
        onExited: function(code) {
            let succeeded = false
            if (code === 0)
                succeeded = root.loadStatus()
            else {
                root.statusKnown = false
                root.reportedAxisLocked = false
                root.error = statusError.text.trim() || "Workspace presentation status is unavailable."
            }
            root.finishStatus(succeeded)
        }
    }

    Process {
        id: writer
        stdout: StdioCollector {}
        stderr: StdioCollector { id: actionError }
        onExited: function(code) {
            root.finishAction(code === 0,
                code === 0 ? "" : actionError.text.trim() || "Could not update workspace presentation.")
        }
    }

    Timer {
        interval: root.pollInterval
        repeat: true
        running: IslandState.mode === IslandState.navigationMode
            || IslandState.mode === IslandState.workspaceAxisMode
            || IslandState.mode === IslandState.layoutSwitcherMode
        onTriggered: root.refreshIfIdle()
    }
}
