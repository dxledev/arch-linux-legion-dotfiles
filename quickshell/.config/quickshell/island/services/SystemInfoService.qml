import QtQuick
import Quickshell
import Quickshell.Io
import "SystemMetrics.js" as Metrics

Scope {
    id: root
    property int pollInterval: 2000
    property var previousSample: null
    property var sample: ({})
    property real cpuUsage: 0
    property var cpuHistory: []
    property var memoryHistory: []
    property var diskHistory: []
    property string error: ""
    readonly property bool ready: sample.memoryTotal > 0
    readonly property real memoryUsage: ready ? sample.memoryUsed / sample.memoryTotal : 0
    readonly property real diskUsage: sample.diskTotal > 0 ? sample.diskUsed / sample.diskTotal : 0
    readonly property string hostname: host.text().trim()
    readonly property string kernel: kernelFile.text().trim()
    readonly property string processor: (cpuInfo.text().match(/model name\s*:\s*([^\n]+)/) || ["", "Processor"])[1]
    readonly property string uptime: ready ? Metrics.uptime(sample.uptime) : "…"

    function history(values, value) { return values.concat([value]).slice(-30); }
    function refresh() { if (!collector.running) collector.running = true; }
    function acceptSample(value) {
        cpuUsage = Metrics.cpuUsage(previousSample, value);
        previousSample = value;
        sample = value;
        cpuHistory = history(cpuHistory, cpuUsage);
        memoryHistory = history(memoryHistory, memoryUsage);
        diskHistory = history(diskHistory, diskUsage);
        error = "";
    }

    FileView { id: host; path: "/proc/sys/kernel/hostname" }
    FileView { id: kernelFile; path: "/proc/sys/kernel/osrelease" }
    FileView { id: cpuInfo; path: "/proc/cpuinfo" }
    Process {
        id: collector
        command: ["/usr/bin/bash", Qt.resolvedUrl("../scripts/system-info.sh").toString().replace(/^file:\/\//, "")]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.acceptSample(JSON.parse(text)); }
                catch (error) { root.error = "System information unavailable"; }
            }
        }
        onExited: code => { if (code !== 0) root.error = "System information unavailable"; }
    }
    Timer { interval: root.pollInterval; running: true; repeat: true; onTriggered: root.refresh() }
    Component.onCompleted: refresh()
}
