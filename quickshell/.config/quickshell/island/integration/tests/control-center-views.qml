import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"
import "../../components"
import "../../core"
import "../../views"

ShellRoot {
    id: root
    readonly property var monitors: [dp, hdmi, laptop, unsupported]
    StatusWatcher {}

    MonitorBrightness { id: dp; modelData: ({name: "DP-1", model: "ASUS"}) }
    MonitorBrightness { id: hdmi; modelData: ({name: "HDMI-A-1", model: "Acer"}) }
    MonitorBrightness { id: laptop; modelData: ({name: "eDP-1", model: "Laptop"}) }
    MonitorBrightness { id: unsupported; modelData: ({name: "HDMI-A-2", model: "Unknown"}) }

    FloatingWindow {
        visible: true
        implicitWidth: 520
        implicitHeight: 250
        BrightnessControls { id: controls; width: 480; monitors: root.monitors }
        CompactView { id: compact; y: 200; width: implicitWidth; height: implicitHeight }
    }

    IpcHandler {
        target: "controlTest"
        function snapshot(): string {
            return JSON.stringify({
                monitors: root.monitors.map(m => ({name: m.connector, brightness: m.brightness, initialized: m.initialized, supported: m.supported, pending: !isNaN(m.queuedBrightness), writing: m.writer.running})),
                height: controls.implicitHeight, contentHeight: controls.contentHeight,
                nightlight: NightLightService.enabled,
                nightlightReady: NightLightService.ready,
                status: {visible: StatusManager.visible, mode: StatusManager.mode,
                    title: StatusManager.title, duration: compact.transitionDuration},
                label: statusLabel()
            });
        }
        function statusLabel(): var {
            function find(item) {
                if (item.objectName === "status-label") return item;
                for (const child of item.children) {
                    const result = find(child);
                    if (result) return result;
                }
                return null;
            }
            const label = find(compact);
            if (!label) return null;
            const row = label.parent;
            return {font: label.font.family, size: label.font.pixelSize, bold: label.font.bold,
                centered: Math.abs(row.x + row.width / 2 - row.parent.width / 2) < 1
                    && Math.abs(row.width - row.implicitWidth) < 1
                    && label.x + label.width <= row.width + 1};
        }
        function set(name: string, percent: real): void {
            root.monitors.find(m => m.connector === name)?.setBrightness(percent);
        }
        function burst(): void {
            dp.setBrightness(40);
            dp.setBrightness(50);
            dp.setBrightness(64);
        }
        function detach(): void {
            const devices = Object.assign({}, BrightnessService.ddcMonitors);
            delete devices["DP-1"];
            BrightnessService.ddcMonitors = devices;
        }
        function detect(): void { BrightnessService.detect(); }
        function refresh(): void { root.monitors.forEach(m => m.refresh()); }
        function toggle(): void { NightLightService.toggle(); }
    }
}
