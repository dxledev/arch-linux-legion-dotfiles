import QtQuick
import QtTest
import Quickshell
import "../../island"
import "../../core"
import "../../components"
import "../../services"
import "../../views"

ShellRoot {
    id: root
    property int phase: 0
    property int elapsed: 0
    readonly property string stateFile: Quickshell.env("ISLAND_RECORD_STATE_DIR") + "/state.json"
    readonly property string callLog: Quickshell.env("RECORD_CALL_LOG")

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }

    function named(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const found = named(child, name);
            if (found) return found;
        }
        return null;
    }

    function next() { phase++; elapsed = 0; }

    function writeState(json) {
        Quickshell.execDetached(["/usr/bin/sh", "-c", "printf '%s\\n' \"$1\" > \"$2.tmp\" && mv -f \"$2.tmp\" \"$2\"", "sh", json, stateFile]);
    }

    function running(extra) {
        return JSON.stringify(Object.assign({running: true, stopping: false, paused: false, pid: 1, startedAt: Date.now() - 65000,
            pausedAt: 0, pausedTotal: 0, temporary: "/nonexistent", format: "mp4", mode: "screen"}, extra || {}));
    }

    function calls() {
        const request = new XMLHttpRequest();
        request.open("GET", "file://" + callLog, false);
        try { request.send(); } catch (error) { return ""; }
        return request.responseText || "";
    }

    function tick() {
        elapsed += 40;
        if (elapsed > 8000) throw new Error("Timed out in phase " + phase);
        const record = named(controls, "record-start"), pause = named(controls, "record-pause"), stop = named(controls, "record-stop");
        const duration = named(controls, "record-duration"), dot = named(controls, "record-live-dot");
        switch (phase) {
        case 0:
            if (!ThemeService.ready || elapsed < 400) return;
            check(RecorderService.formatDuration(0) === "00:00" && RecorderService.formatDuration(59999) === "00:59"
                && RecorderService.formatDuration(61000) === "01:01" && RecorderService.formatDuration(3723000) === "1:02:03", "Durations read mm:ss and h:mm:ss");
            check(record.enabled && !record.dimmed, "Record is available while idle");
            check(!pause.enabled && pause.dimmed && !stop.enabled && stop.dimmed, "Pause and stop are dimmed while idle");
            check(!indicator.visible, "No clock indicator while idle");
            check(duration.text === "--:--" && !dot.visible, "Idle duration is --:-- with no live dot");
            writeState(running());
            next();
            break;
        case 1:
            if (!RecorderService.running) return;
            check(!record.enabled && record.dimmed, "Record rests while recording");
            check(pause.enabled && !pause.dimmed && stop.enabled && !stop.dimmed, "Pause and stop light up while recording");
            check(/^01:0\d$/.test(duration.text), "The timer counts from the start time: " + duration.text);
            check(dot.visible, "A live dot shows while recording");
            check(indicator.visible && indicator.live, "The clock indicator blinks while recording");
            check(named(indicator, "recording-indicator-stop").enabled, "The clock indicator can be clicked while recording");
            check(input.mouseClick(indicator, indicator.width / 2, indicator.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Click the indicator");
            check(input.mouseClick(pause, pause.width / 2, pause.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Click pause");
            next();
            break;
        case 2:
            if (elapsed < 300) return;
            check(calls().split("\n").includes("pause"), "Pause button runs screen-record pause: " + calls());
            check(calls().split("\n").includes("stop"), "Clicking the indicator runs screen-record stop: " + calls());
            writeState(running({paused: true, pausedAt: Date.now() - 5000}));
            next();
            break;
        case 3:
            if (!RecorderService.paused) return;
            check(pause.description === "Resume recording" && pause.enabled, "Pause turns into resume");
            check(indicator.visible && !indicator.live, "The clock indicator holds still while paused");
            check(named(indicator, "recording-indicator-stop").enabled, "A paused recording can still be stopped from the indicator");
            check(/^01:0\d$/.test(duration.text) && Math.abs(RecorderService.elapsedMs - 60000) < 1500, "A paused timer holds still: " + duration.text);
            writeState(running({stopping: true}));
            next();
            break;
        case 4:
            if (!RecorderService.stopping) return;
            check(duration.text === "Saving…" && !pause.enabled && !stop.enabled && !record.enabled, "Saving locks every control");
            check(!named(indicator, "recording-indicator-stop").enabled, "The indicator does nothing while saving");
            writeState('{"running":false,"stopping":false,"paused":false}');
            next();
            break;
        case 5:
            if (RecorderService.running || RecorderService.stopping) return;
            check(duration.text === "--:--" && record.enabled && !indicator.visible, "Back to idle after saving");
            check(input.mouseClick(record, record.width / 2, record.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Click record");
            next();
            break;
        case 6:
            check(IslandState.mode === IslandState.recordOptionsMode, "Record opens the options popup");
            popupLoader.active = true;
            next();
            break;
        case 7: {
            const popup = popupLoader.item;
            if (!popup || RecorderService.cameras.length === 0) return;
            const webcam = named(popup, "record-webcam");
            check(webcam.enabled, "Webcam is offered when a camera exists");
            check(RecorderService.cameraLabel("/dev/video2") === "Laptop camera (/dev/video2)" && RecorderService.cameraLabel("/dev/video9") === "/dev/video9", "Cameras are named by their kernel name");
            check(RecorderService.directory === "/tmp/recordings-test", "The recordings folder comes from the script");
            check(!RecorderService.canStart || RecorderService.mode !== "window", "Screen mode needs a monitor before it can start");
            RecorderService.monitorName = "DP-1";
            check(input.mouseClick(named(popup, "record-mode-window"), 20, 20, Qt.LeftButton, Qt.NoModifier, 0), "Pick window mode");
            check(RecorderService.mode === "window" && !RecorderService.canStart, "Window mode waits for a window");
            check(input.mouseClick(named(popup, "record-mode-region"), 20, 20, Qt.LeftButton, Qt.NoModifier, 0), "Pick region mode");
            check(RecorderService.mode === "region" && RecorderService.canStart, "Region needs no choice beforehand");
            check(input.mouseClick(named(popup, "record-mode-screen"), 20, 20, Qt.LeftButton, Qt.NoModifier, 0), "Pick screen mode");
            check(input.mouseClick(webcam, 20, 20, Qt.LeftButton, Qt.NoModifier, 0) && RecorderService.webcam, "Turn the webcam on");
            const sound = named(popup, "record-audio");
            check(input.mouseClick(sound, 20, 20, Qt.LeftButton, Qt.NoModifier, 0) && RecorderService.audio, "Turn sound on");
            const start = named(popup, "record-start-button");
            check(start.enabled, "Start is ready");
            check(input.mouseClick(start, start.width / 2, start.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Click start");
            check(IslandState.mode === IslandState.defaultMode, "Start folds the island away");
            next();
            break;
        }
        case 8:
            if (elapsed < 900) return;
            check(calls().split("\n").includes("start --mode screen --monitor DP-1 --webcam --webcam-x 100 --webcam-y 100 --audio"), "Start runs the recorder with the chosen options: " + calls());
            next();
            break;
        case 9: {
            // The webcam can be dragged inside the preview, stopping at the edges and never leaving the target.
            if (RecorderService.busy) return;
            const badge = named(finder, "record-webcam-badge");
            if (elapsed < 400) return;
            check(badge.visible && Math.abs(badge.x + badge.width - (finder.frameX + finder.frameWidth)) < 1 && Math.abs(badge.y + badge.height - (finder.frameY + finder.frameHeight)) < 1, "Webcam starts flush in the bottom right corner: " + badge.x + "," + badge.width);
            // Pointer positions are in the preview's own coordinates, since the badge moves under the pointer.
            const startX = badge.x + badge.width / 2, startY = badge.y + badge.height / 2;
            input.mousePress(finder, startX, startY, Qt.LeftButton, Qt.NoModifier, 0);
            // The badge is the camera's picture, not the whole box the recorder fits it in: 4:3 here.
            check(Math.abs(badge.width / badge.height - 4 / 3) < 0.02 && Math.abs(badge.height - finder.frameHeight * 0.25) < 1, "The badge keeps the camera's proportions: " + badge.width + "x" + badge.height);
            input.mouseMove(finder, startX + 400, startY + 400, 0, Qt.LeftButton, Qt.NoModifier);
            check(finder.webcamX === 100 && finder.maxX < 85 && Math.abs(badge.x + badge.width - (finder.frameX + finder.frameWidth)) < finder.frameWidth * 0.02,
                "Dragged to the right edge, the picture ends at the edge: " + finder.webcamX + " of " + finder.maxX);
            input.mouseMove(finder, startX - 50, startY, 0, Qt.LeftButton, Qt.NoModifier);
            check(Math.abs(finder.webcamX - (finder.maxX - 50 / finder.frameWidth * 100)) < 3 && finder.webcamY === 100, "Dragging moves the webcam: " + finder.webcamX + "," + finder.webcamY);
            input.mouseMove(finder, startX - 400, startY - 400, 0, Qt.LeftButton, Qt.NoModifier);
            check(finder.webcamX === 0 && finder.webcamY === 0, "It stays inside the target and stops at the corner: " + finder.webcamX + "," + finder.webcamY);
            input.mouseRelease(finder, startX - 400, startY - 400, Qt.LeftButton, Qt.NoModifier, 0);
            check(finder.released === 1, "Letting go reports the new place");
            RecorderService.webcamX = 0;
            RecorderService.webcamY = 0;
            RecorderService.mode = "region";
            next();
            break;
        }
        case 10: {
            // Left click records again with the last choices; right click opens the options instead.
            if (RecorderService.busy || !RecorderService.available) return;
            IslandController.reset();
            const record = named(controls, "record-start");
            check(input.mouseClick(record, record.width / 2, record.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Left click record");
            check(IslandState.mode === IslandState.defaultMode, "Left click folds the island away instead of opening options");
            next();
            break;
        }
        case 11: {
            if (elapsed < 900) return;
            const expected = "start --mode region --webcam --webcam-x 0 --webcam-y 0 --audio";
            check(calls().split("\n").includes(expected), "Left click starts with the last settings: " + calls());
            const record = named(controls, "record-start");
            check(input.mouseClick(record, record.width / 2, record.height / 2, Qt.RightButton, Qt.NoModifier, 0), "Right click record");
            check(IslandState.mode === IslandState.recordOptionsMode, "Right click opens the options");
            IslandController.openSettingsSection("screenRecording");
            check(IslandState.mode === IslandState.settingsSectionMode && IslandState.settingsSection === "screenRecording", "Open the screen recording settings");
            RecorderService.chooseDirectory();
            next();
            break;
        }
        case 12:
            check(IslandState.mode === IslandState.defaultMode && RecorderService.choosingDirectory, "The panel folds away while the folder picker is open");
            next();
            break;
        case 13:
            if (RecorderService.choosingDirectory) return;
            check(IslandState.mode === IslandState.settingsSectionMode && IslandState.settingsSection === "screenRecording", "The settings panel returns once the picker closes");
            check(calls().split("\n").includes("choose-directory"), "The picker ran through the script");
            console.log("PASS: recording controls, options popup and recorder hand-off");
            Qt.quit();
            break;
        }
    }

    TestEvent { id: input }
    FloatingWindow {
        visible: true
        color: "#202020"
        implicitWidth: 700
        implicitHeight: 760
        RecordControls { id: controls; x: 20; y: 10 }
        RecordingIndicator { id: indicator; x: 300; y: 20 }
        RecordViewfinder {
            id: finder
            property int released: 0
            x: 20
            y: 600
            width: 512
            height: 150
            screens: [{name: "DP-1", x: 0, y: 0, width: 1920, height: 1080, pixelWidth: 1920, pixelHeight: 1080}]
            mode: "screen"
            monitorName: "DP-1"
            webcam: true
            onWebcamMoved: (x, y) => { webcamX = x; webcamY = y; }
            onWebcamReleased: released++
        }
        Loader {
            id: popupLoader
            active: false
            x: 20
            y: 60
            width: 560
            sourceComponent: RecordOptionsView {}
        }
    }
    Timer {
        interval: 40
        running: true
        repeat: true
        onTriggered: {
            try { root.tick(); }
            catch (error) { console.error("FAIL: phase " + root.phase + ": " + error); Qt.quit(); }
        }
    }
}
