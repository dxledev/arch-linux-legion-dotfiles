pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.integration
import "AIUsageParser.js" as Parser

Singleton {
    id: root

    property var entries: []
    property string primaryId: ""
    property string selectedId: ""
    property bool hasReport: false
    property bool loading: false
    property bool stale: false
    property string refreshError: ""
    property double clockNow: Date.now()
    property double lastStartedAt: 0

    readonly property var availableEntries: Parser.availableEntries(entries)
    readonly property var selectedEntry: availableEntries.find(entry => entry.id === selectedId) ?? null

    function selectEntry(id: string): void {
        if (availableEntries.some(entry => entry.id === id))
            selectedId = id;
    }

    function refresh(): void {
        if (usageProcess.running || cooldown.running)
            return;

        const delay = 2000 - (Date.now() - lastStartedAt);
        if (lastStartedAt > 0 && delay > 0) {
            cooldown.interval = delay;
            cooldown.start();
            return;
        }

        startRefresh();
    }

    function startRefresh(): void {
        if (usageProcess.running)
            return;

        lastStartedAt = Date.now();
        loading = true;
        refreshError = "";
        usageProcess.running = true;
    }

    function finishRefresh(exitCode: int, output: string): void {
        loading = false;

        const result = Parser.parseProcessResult(exitCode, output, exitCode === 124 || exitCode === 137);
        const next = Parser.applyResult(entries, hasReport, result);
        entries = next.entries;
        hasReport = next.hasReport;
        stale = next.stale;
        refreshError = next.refreshError;

        if (!result.ok)
            return;

        primaryId = result.report.primary;
        if (!availableEntries.some(entry => entry.id === selectedId)) {
            const primaryEntry = availableEntries.find(entry => entry.id === primaryId);
            selectedId = primaryEntry?.id ?? availableEntries[0]?.id ?? "";
        }
    }

    Component.onCompleted: refresh()

    Process {
        id: usageProcess

        command: ["/usr/bin/timeout", "--signal=TERM", "--kill-after=1s", "30s", "/usr/bin/ai-usagebar", "usage", "--json"]

        stdout: StdioCollector {
            id: reportOutput
        }

        stderr: StdioCollector {}

        onExited: exitCode => root.finishRefresh(exitCode, reportOutput.text ?? "")
    }

    Timer {
        id: refreshTimer

        interval: Math.max(1000, System.aiUsageRefreshIntervalSeconds * 1000)
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Timer {
        id: cooldown

        onTriggered: root.startRefresh()
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.clockNow = Date.now()
    }
}
