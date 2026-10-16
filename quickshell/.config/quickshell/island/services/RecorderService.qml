pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Screen recording through gpu-screen-recorder, driven by integration/screen-record. The script keeps the
// recorder detached and writes its state to a JSON file; this singleton only watches that file, so a shell
// reload mid-recording, a keybind and the buttons all see the same recording.
Singleton {
    id: root

    readonly property string script: Quickshell.env("ISLAND_SCREEN_RECORD_SCRIPT") || Quickshell.shellPath("integration/screen-record")
    readonly property string stateDirectory: Quickshell.env("ISLAND_RECORD_STATE_DIR")
        || (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/island-screen-record"

    // From the state file.
    property bool running: false
    property bool paused: false
    property bool stopping: false
    property real startedAt: 0
    property real pausedAt: 0
    property real pausedTotal: 0

    // What the options popup will record. Kept for the session so the next recording starts from the last choice.
    property string mode: "screen"
    property string monitorName: ""
    property string windowAddress: ""
    property bool webcam: false
    property bool audio: false
    // Where the webcam's top-left corner sits in the video, in percent; 100 is against the edge.
    property real webcamX: 100
    property real webcamY: 100
    property bool hydrated: false

    // True from pressing Start until the recorder is up (a region is being picked, or the island is still closing).
    readonly property bool starting: startDelay.running || startProcess.running
    readonly property bool busy: starting || stopping || stopProcess.running
    readonly property bool active: running || stopping
    property string error: ""
    property var cameras: []
    // Camera device -> name, so two webcams can be told apart.
    property var cameraNames: ({})
    // Camera device -> width over height of its picture.
    property var cameraAspects: ({})
    // The camera the recorder will use: the chosen one, else the first found.
    readonly property string activeCamera: {
        const chosen = String(ThemeService.settings.recordCameraDevice ?? "auto");
        return cameras.includes(chosen) ? chosen : (cameras[0] ?? "");
    }
    readonly property real cameraAspect: cameraAspects[activeCamera] ?? 4 / 3
    // Where recordings go, resolved the way the recorder resolves it (the default folder when none is set).
    property string directory: ""
    readonly property string configuredDirectory: String(ThemeService.settings.recordDirectory ?? "")
    onConfiguredDirectoryChanged: refreshDirectory()
    readonly property bool choosingDirectory: chooseProcess.running
    readonly property string shortDirectory: {
        const home = Quickshell.env("HOME");
        return home && directory.startsWith(home + "/") ? "~" + directory.slice(home.length) : directory;
    }

    // The clock the timer reads. Only ticks while time is actually being recorded.
    property real now: Date.now()
    readonly property real elapsedMs: {
        if (!running) return 0;
        const end = paused ? pausedAt : now;
        return Math.max(0, end - startedAt - pausedTotal);
    }
    readonly property string elapsedText: running ? formatDuration(elapsedMs) : "--:--"

    function pad(value) { return value < 10 ? "0" + value : String(value); }

    function formatDuration(milliseconds) {
        const total = Math.floor(milliseconds / 1000);
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor(total % 3600 / 60);
        const seconds = total % 60;
        return hours > 0 ? hours + ":" + pad(minutes) + ":" + pad(seconds) : pad(minutes) + ":" + pad(seconds);
    }

    // Arguments for `screen-record start` from the popup's choices; "" explains what is still missing.
    function startArguments() {
        const args = ["start", "--mode", mode];
        if (mode === "screen") args.push("--monitor", monitorName);
        if (mode === "window") args.push("--window", windowAddress);
        if (webcam) args.push("--webcam", "--webcam-x", String(Math.round(webcamX)), "--webcam-y", String(Math.round(webcamY)));
        if (audio) args.push("--audio");
        return args;
    }

    // Nothing is recording or about to: a new recording may be set up.
    readonly property bool available: !active && !busy
    readonly property bool canStart: available
        && (mode === "region" || (mode === "screen" && monitorName !== "") || (mode === "window" && windowAddress !== ""))

    // The island folds away first, so neither it nor the options popup is in the first frames or in the way
    // of the region selection.
    function start() {
        if (!canStart) return;
        error = "";
        saveChoices();
        startDelay.restart();
    }

    // The record button's left click: record again with the choices of last time. False when those choices
    // cannot be used as they are (a window that has since closed), so the caller opens the options instead.
    function quickStart() {
        if (!available) return false;
        if (mode === "screen") {
            const names = Hyprland.monitors.values.map(monitor => monitor.name);
            if (!names.includes(monitorName)) monitorName = Hyprland.focusedMonitor?.name ?? names[0] ?? "";
        }
        if (mode === "window" && !Hyprland.toplevels.values.some(toplevel => toplevel.lastIpcObject?.address === windowAddress))
            return false;
        if (!canStart) return false;
        start();
        return true;
    }

    // What was chosen survives restarts, so the record button can repeat it. Only changed values are written.
    function saveChoices() {
        const values = {
            recordMode: mode, recordMonitor: monitorName, recordWebcam: webcam, recordAudio: audio,
            recordWebcamX: Math.round(webcamX), recordWebcamY: Math.round(webcamY)
        };
        for (const key of Object.keys(values))
            if (ThemeService.settings[key] !== values[key]) ThemeService.setSetting(key, values[key]);
    }

    function hydrate() {
        if (hydrated || !ThemeService.ready) return;
        hydrated = true;
        const settings = ThemeService.settings;
        mode = settings.recordMode || "screen";
        monitorName = settings.recordMonitor || "";
        webcam = settings.recordWebcam ?? false;
        audio = settings.recordAudio ?? false;
        webcamX = settings.recordWebcamX ?? 100;
        webcamY = settings.recordWebcamY ?? 100;
    }

    Connections {
        target: ThemeService
        function onReadyChanged() { root.hydrate(); }
    }
    Component.onCompleted: hydrate()

    function stop() {
        if (!running || stopping || stopProcess.running) return;
        stopProcess.running = true;
    }

    function togglePause() {
        if (!running || stopping || pauseProcess.running) return;
        pauseProcess.running = true;
    }

    function refresh() {
        if (!statusProcess.running) statusProcess.running = true;
    }

    // Asks for a recordings folder with the desktop's folder picker and keeps the choice. Closing the picker
    // without choosing changes nothing.
    function chooseDirectory() {
        if (choosingDirectory) return;
        directoryPickerOpening();
        chooseProcess.running = true;
    }

    // The picker is about to open, and has closed again (whether or not a folder was chosen), so the island can
    // step out of its way and come back.
    signal directoryPickerOpening()
    signal directoryPickerClosed()

    function refreshDirectory() {
        directoryProcess.running = false;
        directoryProcess.running = true;
    }

    function cameraLabel(device) {
        const name = cameraNames[device];
        return name ? name + " (" + device + ")" : device;
    }

    function refreshCameras() {
        if (!cameraProcess.running) cameraProcess.running = true;
    }

    function apply(text) {
        let state = {};
        try { state = JSON.parse(text); } catch (err) { return; }
        running = state.running === true;
        stopping = state.stopping === true;
        paused = running && state.paused === true;
        startedAt = running ? Number(state.startedAt) || 0 : 0;
        pausedAt = running ? Number(state.pausedAt) || 0 : 0;
        pausedTotal = running ? Number(state.pausedTotal) || 0 : 0;
        now = Date.now();
    }

    Timer {
        id: startDelay
        interval: 450
        onTriggered: {
            startProcess.command = [root.script, ...root.startArguments()];
            startProcess.running = true;
        }
    }

    Process {
        id: startProcess
        stderr: StdioCollector { id: startError }
        onExited: function(code) {
            if (code !== 0) root.error = startError.text.trim();
            root.refresh();
        }
    }

    Process {
        id: stopProcess
        command: [root.script, "stop"]
        stderr: StdioCollector { id: stopError }
        onExited: function(code) {
            if (code !== 0) root.error = stopError.text.trim();
            root.refresh();
        }
    }

    Process {
        id: pauseProcess
        command: [root.script, "pause"]
        onExited: root.refresh()
    }

    // Also reaps a recording whose recorder ended on its own, so a dead one never shows as running.
    Process {
        id: statusProcess
        command: [root.script, "status"]
        running: true
        stdout: StdioCollector { id: statusOutput }
        onExited: function(code) { if (code === 0) root.apply(statusOutput.text); }
    }

    Process {
        id: cameraProcess
        command: [root.script, "cameras"]
        stdout: StdioCollector { id: cameraOutput }
        onExited: function(code) {
            if (code !== 0) return;
            const rows = cameraOutput.text.split("\n").map(line => line.trim().split("|")).filter(row => row[0].length > 0);
            const names = {}, aspects = {};
            for (const row of rows) {
                names[row[0]] = row[1] ?? "";
                const size = (row[2] ?? "").split("x").map(Number);
                if (size.length === 2 && size[0] > 0 && size[1] > 0) aspects[row[0]] = size[0] / size[1];
            }
            root.cameraNames = names;
            root.cameraAspects = aspects;
            root.cameras = rows.map(row => row[0]);
        }
    }

    Process {
        id: chooseProcess
        command: [root.script, "choose-directory"]
        stdout: StdioCollector { id: chooseOutput }
        onExited: function(code) {
            const path = chooseOutput.text.trim();
            if (code === 0 && path !== "") ThemeService.setSetting("recordDirectory", path);
            root.directoryPickerClosed();
        }
    }

    Process {
        id: directoryProcess
        command: [root.script, "directory"]
        running: true
        stdout: StdioCollector { id: directoryOutput }
        onExited: function(code) { if (code === 0) root.directory = directoryOutput.text.trim(); }
    }

    FileView {
        path: root.stateDirectory + "/state.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.apply(text())
    }

    Timer {
        interval: 250
        repeat: true
        running: root.running && !root.paused && !root.stopping
        onTriggered: root.now = Date.now()
    }

    // The recorder can end without being asked to; the script notices and tidies up when asked.
    Timer {
        interval: 5000
        repeat: true
        running: root.running && !root.stopping
        onTriggered: root.refresh()
    }
}
