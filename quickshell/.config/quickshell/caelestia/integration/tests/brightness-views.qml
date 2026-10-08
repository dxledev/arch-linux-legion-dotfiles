pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Io
import "services" as Services
import "integration" as Integration

Scope {
    id: root

    property var initialReadings: ({})

    Instantiator {
        model: Services.Brightness.monitors
        delegate: Connections {
            required property var modelData
            target: modelData
            function onInitializedChanged(): void {
                if (modelData.initialized && root.initialReadings[modelData.modelData.name] === undefined)
                    root.initialReadings = Object.assign({}, root.initialReadings, {
                        [modelData.modelData.name]: Math.round(modelData.brightness * 100)
                    });
            }
        }
    }

    IpcHandler {
        target: "brightnessTest"

        function snapshot(): string {
            return JSON.stringify({
                initialReadings: root.initialReadings,
                monitors: Services.Brightness.monitors.map(monitor => ({
                    connector: monitor.modelData.name,
                    brightness: Math.round(monitor.brightness * 100),
                    initialized: monitor.initialized,
                    supported: monitor.supported,
                    writing: monitor.writeProc.running,
                    pending: !isNaN(monitor.queuedBrightness)
                }))
            });
        }

        function set(connector: string, value: real): void {
            Services.Brightness.getMonitor(connector).setBrightness(value);
        }

        function refresh(): void {
            for (const monitor of Services.Brightness.monitors)
                monitor.initBrightness();
        }

        function setPolling(enabled: bool): void {
            Integration.System.brightnessDdcPolling = enabled;
        }

        function burst(): void {
            const monitor = Services.Brightness.getMonitor("DP-1");
            for (const value of [0.32, 0.36, 0.40])
                monitor.setBrightness(value);
        }

        function changeBus(): void {
            Services.Brightness.ddcMonitors = [
                {connector: "DP-1", busNum: "6"},
                {connector: "HDMI-A-1", busNum: "4"},
                {connector: "DP-2", busNum: "8"}
            ];
        }
    }
}
