pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components.misc
import qs.integration

Singleton {
    id: root

    property list<var> ddcMonitors: []
    property bool detectionPending: false
    property bool detectionFailed: false
    readonly property var ddcMonitorMap: {
        const map = {};
        for (const m of ddcMonitors)
            map[m.connector] = m;
        return map;
    }
    readonly property list<Monitor> monitors: variants.instances // qmllint disable incompatible-type
    property bool appleDisplayPresent: false
    readonly property var osdMonitors: {
        const ordered = System.brightnessMonitors.map(entry => getMonitor(entry.connector)).filter(Boolean);
        for (const monitor of monitors)
            if (!ordered.includes(monitor))
                ordered.push(monitor);
        return ordered.filter(monitor => monitor.supported);
    }
    readonly property bool combinedOsd: DisplaySettings.layoutFor(Quickshell.screens.length) === "combined"

    function osdMonitorsFor(screen: ShellScreen): var {
        return combinedOsd ? osdMonitors : osdMonitors.filter(monitor => monitor.modelData === screen);
    }

    function getMonitorForScreen(screen: ShellScreen): var {
        return monitors.find(m => m.modelData === screen); // qmllint disable missing-property
    }

    function getMonitor(query: string): var {
        if (query === "active") {
            return monitors.find(m => Hypr.monitorFor(m.modelData)?.focused); // qmllint disable missing-property
        }

        if (query.startsWith("model:")) {
            const model = query.slice(6);
            return monitors.find(m => m.modelData.model === model); // qmllint disable missing-property
        }

        if (query.startsWith("serial:")) {
            const serial = query.slice(7);
            return monitors.find(m => m.modelData.serialNumber === serial); // qmllint disable missing-property
        }

        if (query.startsWith("id:")) {
            const id = parseInt(query.slice(3), 10);
            return monitors.find(m => Hypr.monitorFor(m.modelData)?.id === id); // qmllint disable missing-property
        }

        return monitors.find(m => m.modelData.name === query); // qmllint disable missing-property
    }

    function increaseBrightness(): void {
        const monitor = getMonitor("active");
        if (monitor)
            monitor.setBrightness(monitor.brightness + GlobalConfig.services.brightnessIncrement);
    }

    function decreaseBrightness(): void {
        const monitor = getMonitor("active");
        if (monitor)
            monitor.setBrightness(monitor.brightness - GlobalConfig.services.brightnessIncrement);
    }

    function detectMonitors(): void {
        if (ddcProc.running)
            detectionPending = true;
        else
            ddcProc.running = true;
    }

    onMonitorsChanged: Qt.callLater(detectMonitors)

    Variants {
        id: variants

        model: Quickshell.screens // Don't respect excluded screens cause ipc

        Monitor {}
    }

    Process {
        running: true
        command: ["sh", "-c", "asdbctl get"] // To avoid warnings if asdbctl is not installed
        stdout: StdioCollector {
            onStreamFinished: root.appleDisplayPresent = text.trim().length > 0
        }
    }

    Process {
        id: ddcProc

        command: ["ddcutil", "detect", "--brief"]
        stdout: StdioCollector { id: detectionOutput }
        onExited: code => {
            root.detectionFailed = code !== 0;
            if (code === 0) {
                const monitors = [];
                for (const block of detectionOutput.text.trim().split(/\n\s*\n/)) {
                    if (!block.startsWith("Display "))
                        continue;
                    const bus = block.match(/I2C bus:\s*\/dev\/i2c-(\d+)/);
                    const connector = block.match(/DRM connector:\s*(\S+)/);
                    if (bus && connector)
                        monitors.push({busNum: bus[1], connector: connector[1].replace(/^card\d+-/, "")});
                }
                root.ddcMonitors = monitors;
            }
            if (root.detectionPending) {
                root.detectionPending = false;
                Qt.callLater(root.detectMonitors);
            }
        }
    }

    Timer {
        interval: System.brightnessPollInterval
        repeat: true
        running: root.detectionFailed
        onTriggered: root.detectMonitors()
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "brightnessUp"
        description: "Increase brightness"
        onPressed: root.increaseBrightness()
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "brightnessDown"
        description: "Decrease brightness"
        onPressed: root.decreaseBrightness()
    }

    IpcHandler {
        function get(): real {
            return getFor("active");
        }

        // Allows searching by active/model/serial/id/name
        function getFor(query: string): real {
            return root.getMonitor(query)?.brightness ?? -1;
        }

        function refresh(): void {
            for (const monitor of root.monitors)
                monitor.initBrightness();
        }

        function status(): string {
            return JSON.stringify({
                layout: root.combinedOsd ? "combined" : "local",
                monitors: root.monitors.map(monitor => ({
                    connector: monitor.modelData.name,
                    name: monitor.displayName,
                    brightness: monitor.brightness,
                    supported: monitor.supported,
                    initialized: monitor.initialized,
                    panelTargets: root.osdMonitorsFor(monitor.modelData).map(target => target.modelData.name)
                }))
            });
        }

        function set(value: string): string {
            return setFor("active", value);
        }

        // Handles brightness value like brightnessctl: 0.1, +0.1, 0.1-, 10%, +10%, 10%-
        function setFor(query: string, value: string): string {
            const monitor = root.getMonitor(query);
            if (!monitor)
                return "Invalid monitor: " + query;
            if (!monitor.supported)
                return "Brightness unavailable for monitor: " + query;
            if (!monitor.initialized)
                return "Brightness not ready for monitor: " + query;

            let targetBrightness;
            if (value.endsWith("%-")) {
                const percent = parseFloat(value.slice(0, -2));
                targetBrightness = monitor.brightness - (percent / 100);
            } else if (value.startsWith("+") && value.endsWith("%")) {
                const percent = parseFloat(value.slice(1, -1));
                targetBrightness = monitor.brightness + (percent / 100);
            } else if (value.endsWith("%")) {
                const percent = parseFloat(value.slice(0, -1));
                targetBrightness = percent / 100;
            } else if (value.startsWith("+")) {
                const increment = parseFloat(value.slice(1));
                targetBrightness = monitor.brightness + increment;
            } else if (value.endsWith("-")) {
                const decrement = parseFloat(value.slice(0, -1));
                targetBrightness = monitor.brightness - decrement;
            } else if (value.includes("%") || value.includes("-") || value.includes("+")) {
                return `Invalid brightness format: ${value}\nExpected: 0.1, +0.1, 0.1-, 10%, +10%, 10%-`;
            } else {
                targetBrightness = parseFloat(value);
            }

            if (isNaN(targetBrightness))
                return `Failed to parse value: ${value}\nExpected: 0.1, +0.1, 0.1-, 10%, +10%, 10%-`;

            monitor.setBrightness(targetBrightness);

            return `Set monitor ${monitor.modelData.name} brightness to ${+monitor.brightness.toFixed(2)}`;
        }

        target: "brightness"
    }

    component Monitor: QtObject {
        id: monitor

        required property ShellScreen modelData
        readonly property var ddcInfo: root.ddcMonitorMap[modelData.name] ?? null
        readonly property bool isDdc: ddcInfo !== null
        readonly property bool isBacklight: /^(eDP|LVDS|DSI)-/i.test(modelData.name)
        readonly property string busNum: ddcInfo?.busNum ?? ""
        readonly property bool isAppleDisplay: root.appleDisplayPresent && modelData.model.startsWith("StudioDisplay")
        readonly property bool supported: isDdc || isBacklight || isAppleDisplay
        readonly property string displayName: DisplaySettings.nameFor(modelData.name)
        readonly property string label: DisplaySettings.nickname(modelData.name)
            || System.brightnessMonitors.find(entry => entry.connector === modelData.name)?.label || modelData.name
        property real brightness
        property real queuedBrightness: NaN
        property bool initialized: false
        readonly property string ddcScript: Quickshell.shellPath("integration/monitor-brightness")
        readonly property string stateDirectory: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/system-brightness-ddc/"

        readonly property Process initProc: Process {
            property string bus
            stdout: StdioCollector { id: initialOutput }
            onExited: code => {
                if (code === 0 && bus === monitor.busNum && !writeProc.running && isNaN(monitor.queuedBrightness)) {
                    const text = initialOutput.text;
                    if (monitor.isDdc) {
                        const percent = Number(text.trim());
                        if (text.trim() && Number.isFinite(percent) && percent >= 0 && percent <= 100) {
                            monitor.brightness = percent / 100;
                            monitor.initialized = true;
                        }
                    } else if (monitor.isAppleDisplay) {
                        const val = parseInt(text.trim());
                        if (Number.isFinite(val)) {
                            monitor.brightness = val / 101;
                            monitor.initialized = true;
                        }
                    } else {
                        const [, , , cur, max] = text.split(" ");
                        const value = parseInt(cur) / parseInt(max);
                        if (Number.isFinite(value)) {
                            monitor.brightness = value;
                            monitor.initialized = true;
                        }
                    }
                }
                if (!isNaN(monitor.queuedBrightness))
                    timer.restart();
            }
        }

        readonly property Timer refreshTimer: Timer {
            interval: System.brightnessPollInterval
            repeat: true
            running: monitor.supported && (!monitor.isDdc || !monitor.initialized || System.brightnessDdcPolling)
            onTriggered: monitor.initBrightness()
        }

        readonly property Timer timer: Timer {
            interval: System.brightnessWriteDelay
            onTriggered: monitor.flushBrightness()
        }

        readonly property Process writeProc: Process {
            onExited: code => {
                if (code !== 0) {
                    console.warn("Failed to set brightness for", monitor.modelData.name);
                    monitor.initBrightness();
                }
                cachedState.reload();
                timer.restart();
            }
        }

        readonly property FileView cachedState: FileView {
            path: monitor.isDdc ? monitor.stateDirectory + monitor.modelData.name + ".state" : ""
            watchChanges: true
            printErrors: false
            onFileChanged: reload()
            onLoaded: monitor.readCache(text())
        }

        readonly property FileView shortcutState: FileView {
            path: monitor.isDdc ? monitor.stateDirectory + monitor.modelData.name.replace(/-\d+$/, "") + ".state" : ""
            watchChanges: true
            printErrors: false
            onFileChanged: reload()
            onLoaded: monitor.readCache(text())
        }

        function readCache(text: string): void {
            const fields = text.trim().split("\n");
            const percent = Number(fields[2]);
            if (initialized && fields.length === 4 && fields[0] === busNum && fields[2].trim()
                    && Number.isFinite(percent) && percent >= 0 && percent <= 100
                    && !initProc.running && !writeProc.running && isNaN(queuedBrightness))
                brightness = percent / 100;
        }

        function flushBrightness(): void {
            if (writeProc.running || initProc.running || timer.running || isNaN(queuedBrightness)) {
                if (!isNaN(queuedBrightness) && !timer.running)
                    timer.start();
                return;
            }
            const percent = Math.round(queuedBrightness * 100);
            queuedBrightness = NaN;
            writeProc.command = ["/usr/bin/bash", ddcScript, modelData.name, busNum, "set", String(percent)];
            writeProc.running = true;
        }

        function setBrightness(value: real): void {
            if (!supported || !initialized || !Number.isFinite(value))
                return;
            value = Math.max(0, Math.min(1, value));
            const rounded = Math.round(value * 100);
            if (Math.round(brightness * 100) === rounded)
                return;

            brightness = value;

            if (isAppleDisplay)
                Quickshell.execDetached(["asdbctl", "set", rounded]);
            else if (isDdc) {
                queuedBrightness = value;
                flushBrightness();
            } else if (isBacklight)
                Quickshell.execDetached(["brightnessctl", "s", `${rounded}%`]);
        }

        function initBrightness(): void {
            if (!supported || (isDdc && !busNum) || initProc.running || writeProc.running || !isNaN(queuedBrightness))
                return;
            initProc.bus = busNum;
            if (isAppleDisplay)
                initProc.command = ["asdbctl", "get"];
            else if (isDdc)
                initProc.command = ["/usr/bin/bash", ddcScript, modelData.name, busNum, "get"];
            else
                initProc.command = ["sh", "-c", "echo a b c $(brightnessctl g) $(brightnessctl m)"];

            initProc.running = true;
        }

        onBusNumChanged: {
            initialized = false;
            queuedBrightness = NaN;
            Qt.callLater(initBrightness);
        }
        onSupportedChanged: {
            initialized = false;
            Qt.callLater(initBrightness);
        }
        Component.onCompleted: Qt.callLater(initBrightness)
    }
}
