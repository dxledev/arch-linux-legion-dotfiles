pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "AIUsageProviders.js" as Providers
import "AIUsageParser.js" as Parser

Singleton {
    id: root

    property var entries: []
    property var providerIds: []
    property string primaryId: ""
    property string selectedId: ""
    property bool hasReport: false
    property bool loading: false
    property bool stale: false
    property string refreshError: ""
    property double clockNow: Date.now()
    property double lastStartedAt: 0

    readonly property var availableEntries: Providers.availableEntries(entries, providerIds)
    readonly property var selectedEntry: availableEntries.find(entry => entry.id === selectedId) ?? null
    readonly property string usageBinary: {
        const candidate = Quickshell.env("ISLAND_AI_USAGE_BIN") || "/usr/bin/ai-usagebar";
        return candidate.startsWith("/") ? candidate : "/usr/bin/ai-usagebar";
    }
    readonly property string configOverride: {
        const candidate = Quickshell.env("ISLAND_AI_USAGE_CONFIG") || "";
        return candidate.startsWith("/") ? candidate : "";
    }
    readonly property int refreshIntervalSeconds: {
        const setting = String(Quickshell.env("ISLAND_AI_USAGE_REFRESH_INTERVAL_SECONDS") ?? "");
        const value = setting.length > 0 ? Number(setting) : NaN;
        return Number.isFinite(value) && value > 0 ? Math.max(1, Math.min(86400, Math.round(value))) : 300;
    }
    readonly property int timeoutSeconds: {
        const setting = String(Quickshell.env("ISLAND_AI_USAGE_TIMEOUT_SECONDS") ?? "");
        const value = setting.length > 0 ? Number(setting) : NaN;
        return Number.isFinite(value) && value > 0 ? Math.max(1, Math.min(300, Math.round(value))) : 30;
    }

    function selectEntry(id: string): void {
        if (availableEntries.some(entry => entry.id === id))
            selectedId = id;
    }

    function reconcileSelection(preferredId = primaryId): void {
        if (availableEntries.some(entry => entry.id === selectedId))
            return;

        const preferredEntry = availableEntries.find(entry => entry.id === preferredId);
        selectedId = preferredEntry?.id ?? availableEntries[0]?.id ?? "";
    }

    function refresh(): void {
        if (discoveryProcess.running || usageProcess.running || cooldown.running)
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
        if (discoveryProcess.running || usageProcess.running)
            return;

        lastStartedAt = Date.now();
        loading = true;
        refreshError = "";
        discoveryProcess.running = true;
    }

    function finishFailure(message: string): void {
        loading = false;
        stale = true;
        refreshError = message;
    }

    function finishDiscovery(exitCode: int, output: string): void {
        const result = Providers.parseDiscoveryResult(exitCode, output, exitCode === 124 || exitCode === 137);
        if (!result.ok) {
            finishFailure(result.message);
            return;
        }

        providerIds = result.providerIds;
        reconcileSelection();
        if (providerIds.length === 0) {
            entries = [];
            primaryId = "";
            selectedId = "";
            hasReport = true;
            loading = false;
            stale = false;
            refreshError = "";
            return;
        }

        usageProcess.running = true;
    }

    function finishReport(exitCode: int, output: string): void {
        const result = Parser.parseProcessResult(exitCode, output, exitCode === 124 || exitCode === 137);
        if (!result.ok) {
            finishFailure(result.message);
            return;
        }

        entries = result.report.entries.map(entry => entry.failed
            ? Object.assign({}, entry, {error: "Provider usage could not be refreshed."})
            : entry);
        primaryId = result.report.primary;
        reconcileSelection(primaryId);
        hasReport = true;
        loading = false;
        stale = false;
        refreshError = "";
    }

    Component.onCompleted: refresh()

    Process {
        id: discoveryProcess

        command: {
            const discoveryPath = Qt.resolvedUrl("../integration/ai-usage-discovery.py").toString().replace(/^file:\/\//, "");
            const commandArgs = ["/usr/bin/timeout", "--signal=TERM", "--kill-after=1s", `${root.timeoutSeconds}s`, "/usr/bin/python3", discoveryPath, root.usageBinary];
            if (root.configOverride.length > 0)
                commandArgs.push(root.configOverride);
            return commandArgs;
        }

        stdout: StdioCollector {
            id: discoveryOutput
        }

        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => root.finishDiscovery(exitCode, discoveryOutput.text ?? "")
    }

    Process {
        id: usageProcess

        command: {
            const commandArgs = ["/usr/bin/timeout", "--signal=TERM", "--kill-after=1s", `${root.timeoutSeconds}s`, root.usageBinary, "usage", "--json"];
            if (root.configOverride.length > 0)
                commandArgs.push("--config", root.configOverride);
            return commandArgs;
        }

        stdout: StdioCollector {
            id: reportOutput
        }

        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => root.finishReport(exitCode, reportOutput.text ?? "")
    }

    Timer {
        id: refreshTimer

        interval: Math.max(1000, root.refreshIntervalSeconds * 1000)
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
