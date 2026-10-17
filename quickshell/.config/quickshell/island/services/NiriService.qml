pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "NiriModel.js" as NiriModel

// niri's side of Compositor: one long-lived `niri msg --json event-stream` keeps workspaces, windows and
// the keyboard layout current, and a few `niri msg` calls cover what the stream leaves out (outputs).
// Nothing runs unless niri is the compositor. ISLAND_NIRI_BIN points at another niri binary (the tests'
// mock, for one).
Singleton {
    id: root

    readonly property bool active: NiriModel.detectWith(variable => Quickshell.env(variable)) === "niri"
    readonly property string binary: Quickshell.env("ISLAND_NIRI_BIN") || "niri"

    property var state: NiriModel.emptyState()
    property var outputs: ({})
    property bool connected: false

    readonly property string focusedOutput: NiriModel.focusedOutput(state)
    // Hyprland-shaped workspace records. Rebuilt after every event but only replaced when they differ, so
    // the window-layout events that fill the stream while scrolling do not wake the workspace views.
    property var workspaces: []
    readonly property var focusedWorkspace: workspaces.find(workspace => workspace.focused) ?? null
    readonly property var monitors: NiriModel.monitorModels(outputs, workspaces, focusedOutput)
    readonly property string keyboardLayoutName: state.keyboard.names[state.keyboard.current_idx] ?? ""
    readonly property bool overviewOpen: state.overviewOpen

    // The workspace that just became active on the focused monitor, for the workspace OSD.
    signal workspaceFocused()
    signal outputsRefreshed()
    signal configLoaded()

    // A spawn waiting for its window: {known, width, height, appIdHint}.
    property var pendingFloat: null

    function monitorFor(screen) {
        return screen ? monitors[screen.name] ?? null : null;
    }

    function action(arguments_) {
        Quickshell.execDetached([binary, "msg", "action"].concat(arguments_));
    }

    // niri's `focus-workspace <n>` acts on the focused monitor, so move there first when the panel that was
    // clicked belongs to another one.
    function focusWorkspace(index, monitorName) {
        const script = '"$0" msg action focus-monitor "$1" && "$0" msg action focus-workspace "$2"';
        if (monitorName && monitorName !== focusedOutput)
            Quickshell.execDetached(["sh", "-c", script, binary, monitorName, String(index)]);
        else
            action(["focus-workspace", String(index)]);
    }

    // `hyprctl monitors -j` / `clients -j` shaped records for the recorder, built when asked for.
    function recordMonitors() {
        return NiriModel.recordMonitors(outputs, workspaces, focusedOutput);
    }

    function recordClients() {
        return NiriModel.recordClients(state, outputs, workspaces, recordMonitors());
    }

    function refreshOutputs() {
        if (active && !outputReader.running) outputReader.running = true;
    }

    // niri has no per-spawn window rules, so the window is floated and sized once it opens: the first new
    // window whose app id contains `appIdHint` (any new window when empty). Matching on a new window rather
    // than a pid matters because an app that is already running may open the window from its own process.
    function spawnFloating(command, width, height, appIdHint) {
        const known = {};
        for (const id of Object.keys(state.windows)) known[id] = true;
        pendingFloat = {known: known, width: width, height: height, appIdHint: appIdHint || ""};
        floatExpiry.restart();
        Quickshell.execDetached(command);
    }

    function floatWindow(window) {
        const pending = pendingFloat;
        pendingFloat = null;
        floatExpiry.stop();
        const script = '"$0" msg action move-window-to-floating --id "$1"; '
            + '"$0" msg action set-window-width --id "$1" "$2"; '
            + '"$0" msg action set-window-height --id "$1" "$3"; '
            + '"$0" msg action center-window --id "$1"';
        Quickshell.execDetached(["sh", "-c", script, binary, String(window.id), String(pending.width), String(pending.height)]);
    }

    function handleLine(line) {
        let message;
        try { message = JSON.parse(line); }
        catch (error) { return; }
        const result = NiriModel.applyEvent(state, message);
        if (result.state !== state) {
            state = result.state;
            const models = NiriModel.workspaceModels(state);
            if (JSON.stringify(models) !== JSON.stringify(workspaces)) workspaces = models;
        }
        switch (result.kind) {
        case "WorkspaceActivated":
            if (result.focused) workspaceFocused();
            break;
        case "WindowOpenedOrChanged":
            if (pendingFloat && NiriModel.matchesSpawn(result.window, pendingFloat.known, pendingFloat.appIdHint)) {
                if (result.window.is_floating) {
                    pendingFloat = null;
                    floatExpiry.stop();
                } else {
                    floatWindow(result.window);
                }
            }
            break;
        case "ConfigLoaded":
            configLoaded();
            break;
        }
    }

    Timer {
        id: floatExpiry
        interval: 8000
        onTriggered: root.pendingFloat = null
    }

    Process {
        id: eventStream
        command: [root.binary, "msg", "--json", "event-stream"]
        running: root.active
        stdout: SplitParser {
            onRead: line => root.handleLine(line)
        }
        onStarted: root.connected = true
        onExited: {
            root.connected = false;
            if (root.active) restart.start();
        }
    }

    Timer {
        id: restart
        interval: 2000
        onTriggered: eventStream.running = root.active
    }

    Process {
        id: outputReader
        command: [root.binary, "msg", "--json", "outputs"]
        stdout: StdioCollector {}
        onExited: code => {
            if (code !== 0) return;
            try {
                root.outputs = JSON.parse(stdout.text);
                root.outputsRefreshed();
            } catch (error) {
                console.warn("Could not read niri outputs: " + error);
            }
        }
    }

    // The event stream says nothing about outputs, but Quickshell's screen list changes with them.
    Connections {
        target: Quickshell
        function onScreensChanged() { root.refreshOutputs(); }
    }

    Component.onCompleted: refreshOutputs()
}
