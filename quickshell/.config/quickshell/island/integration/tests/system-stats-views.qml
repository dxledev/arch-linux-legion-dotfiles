import QtQuick
import Quickshell
import "../../views"
import "../../services"

ShellRoot {
    id: root
    property bool firstSampleChecked: false
    property bool serviceDeltaChecked: false

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }

    function named(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children ?? []) {
            const found = named(child, name);
            if (found) return found;
        }
        return null;
    }

    SystemInfoService { id: service; pollInterval: 800 }

    FloatingWindow {
        visible: true
        implicitWidth: 700
        implicitHeight: 460
        SystemView { id: view; width: 600 }
    }

    Timer {
        interval: 25
        running: true
        repeat: true
        onTriggered: {
            try {
                if (service.ready && !root.firstSampleChecked) {
                    root.check(!service.cpuReady && service.cpuHistory.length === 0,
                        "CPU stays in sampling state until a second real counter sample");
                    root.check(service.sample.memoryTotal > 0 && service.sample.memoryUsed <= service.sample.memoryTotal,
                        "Memory values come from valid Linux counters");
                    root.check(service.sample.diskTotal > 0 && service.sample.diskUsed <= service.sample.diskTotal,
                        "Storage values come from the root filesystem counter");
                    root.firstSampleChecked = true;
                }

                if (service.cpuReady && !root.serviceDeltaChecked) {
                    root.check(root.firstSampleChecked && service.cpuHistory.length >= 1,
                        "CPU history begins after a valid counter delta");
                    root.check(Number.isFinite(service.cpuUsage) && service.cpuUsage >= 0 && service.cpuUsage <= 1,
                        "CPU delta stays within the usage range");
                    root.serviceDeltaChecked = true;
                }

                const cpu = root.named(view, "system-cpu");
                const memory = root.named(view, "system-memory");
                const storage = root.named(view, "system-storage");
                if (!cpu || !memory || !storage) return;
                if (!root.serviceDeltaChecked || !cpu.ready || !memory.ready || !storage.ready) return;

                root.check(cpu.ready && memory.ready && storage.ready,
                    "Rendered resource cards leave sampling state after live values arrive");
                console.log("PASS: real Linux first sample, CPU delta, and rendered readiness");
                Qt.quit();
            } catch (error) {
                console.error("FAIL: " + error);
                Qt.quit();
            }
        }
    }
}
