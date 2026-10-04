pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    required property var modelData
    readonly property string connector: modelData.name
    readonly property string label: (modelData.model || connector) + (modelData.model ? " · " + connector : "")
    readonly property string bus: BrightnessService.ddcMonitors[connector] ?? ""
    readonly property string backlight: /^(eDP|LVDS|DSI)-/.test(connector) ? BrightnessService.backlightDevice : ""
    readonly property bool supported: !!bus || !!backlight
    readonly property url icon: BrightnessService.iconFor(brightness)
    readonly property string helper: String(Qt.resolvedUrl("../integration/monitor-brightness")).replace("file://", "")
    readonly property string stateDirectory: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/system-brightness-ddc/"
    property int brightness: 0
    property bool initialized: false
    property string error: ""
    property real queuedBrightness: NaN

    function command(action, percent) {
        if (bus) return ["/usr/bin/bash", helper, connector, bus, action, ...(action === "set" ? [String(percent)] : [])];
        return [BrightnessService.backlightBinary, "--device=" + backlight, "--machine-readable", ...(action === "set" ? ["set", percent + "%"] : ["info"])];
    }

    function readValue(output) {
        const value = bus ? Number(output.trim()) : Number(output.trim().split(",")[3]?.replace("%", ""));
        if (!output.trim() || !Number.isFinite(value) || value < 0 || value > 100) return;
        brightness = Math.round(value);
        initialized = true;
        error = "";
    }

    function refresh() {
        if (!supported || reader.running || writer.running || !isNaN(queuedBrightness)) return;
        reader.command = command("get", 0);
        reader.running = true;
    }

    function setBrightness(value) {
        if (!supported || !initialized || !Number.isFinite(value)) return;
        const percent = Math.max(0, Math.min(100, Math.round(value)));
        if (brightness === percent) return;
        brightness = percent;
        queuedBrightness = percent;
        writeTimer.restart();
    }

    function flush() {
        if (isNaN(queuedBrightness)) return;
        if (reader.running || writer.running) { writeTimer.restart(); return; }
        const percent = queuedBrightness;
        queuedBrightness = NaN;
        writer.command = command("set", percent);
        writer.running = true;
    }

    function readCache(output) {
        const fields = output.trim().split("\n");
        if (fields.length === 4 && fields[0] === bus && !reader.running && !writer.running && isNaN(queuedBrightness))
            readValue(fields[2]);
    }

    onBusChanged: { initialized = false; Qt.callLater(refresh); }
    onBacklightChanged: { initialized = false; Qt.callLater(refresh); }

    readonly property Process reader: Process {
        stdout: StdioCollector { id: readerOutput }
        stderr: StdioCollector {}
        onExited: function(code) {
            if (code === 0 && isNaN(root.queuedBrightness)) root.readValue(readerOutput.text);
            else if (code !== 0) root.error = "Brightness unavailable";
            root.cache.reload();
            root.shortcutCache.reload();
            if (!isNaN(root.queuedBrightness)) root.writeTimer.restart();
        }
    }

    readonly property Process writer: Process {
        stdout: StdioCollector { id: writerOutput }
        stderr: StdioCollector {}
        onExited: function(code) {
            if (code !== 0) { root.error = "Could not set brightness"; root.refresh(); }
            else if (isNaN(root.queuedBrightness)) root.readValue(writerOutput.text);
            root.cache.reload();
            root.shortcutCache.reload();
            if (!isNaN(root.queuedBrightness)) root.writeTimer.restart();
        }
    }

    readonly property Timer writeTimer: Timer {
        interval: BrightnessService.writeDelay
        onTriggered: root.flush()
    }

    readonly property FileView cache: FileView {
        path: root.bus ? root.stateDirectory + root.connector + ".state" : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.readCache(text())
    }

    readonly property FileView shortcutCache: FileView {
        path: root.bus ? root.stateDirectory + root.connector.replace(/-\d+$/, "") + ".state" : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.readCache(text())
    }

    Component.onCompleted: refresh()
}
