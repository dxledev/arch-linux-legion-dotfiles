import QtQuick
import QtTest
import Quickshell
import "../../views"
import "../../services"

ShellRoot {
    id: root
    property int phase: 0
    property double resetAt: Date.now() + 2700000
    property int refreshStart: 0
    property bool singleCaptured: false
    property bool multiCaptured: false
    property bool uiDone: false
    property bool backendDone: false
    property int backendPhase: 0
    property double backendPreviousStart: 0

    function capture(item, variableName, mark) {
        const path = Quickshell.env(variableName);
        if (!path) {
            mark();
            return;
        }
        item.grabToImage(result => {
            check(result.saveToFile(path), "Save " + variableName + " preview");
            mark();
        });
    }

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
    function containsText(item, value) {
        if (!item) return false;
        if (typeof item.text === "string" && item.text.includes(value)) return true;
        for (const child of item.children ?? []) {
            if (containsText(child, value)) return true;
        }
        return false;
    }

    function textList(item, values) {
        if (!item) return values;
        if (typeof item.text === "string" && item.text.length > 0) values.push(item.text);
        for (const child of item.children ?? []) textList(child, values);
        return values;
    }

    function countVisibleText(item, value, parentVisible) {
        if (!item) return 0;
        const isVisible = parentVisible && item.visible !== false;
        let count = isVisible && typeof item.text === "string" && item.text.includes(value) ? 1 : 0;
        for (const child of item.children ?? []) count += countVisibleText(child, value, isVisible);
        return count;
    }

    function click(item) {
        check(item, "Pointer target exists");
        check(input.mouseClick(item, item.width / 2, item.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Deliver pointer click");
    }

    function beginBackendRefresh(nextPhase) {
        backendPreviousStart = AIUsageService.lastStartedAt;
        AIUsageService.refresh();
        backendPhase = nextPhase;
    }

    function backendRefreshFinished() {
        return AIUsageService.lastStartedAt !== backendPreviousStart && !AIUsageService.loading;
    }

    function tickBackend() {
        const service = AIUsageService;
        if (backendPhase === 0) {
            if (!service.hasReport || service.loading) return;
            check(service.refreshIntervalSeconds === 300 && service.timeoutSeconds === 30, "Backend uses the documented refresh and timeout defaults");
            check(JSON.stringify(service.availableEntries.map(entry => entry.id)) === JSON.stringify(["openai", "openai@work", "anthropic@team", "custom:internal"]), "Backend includes only configured base, named and custom accounts");
            check(service.availableEntries.find(entry => entry.id === "anthropic@team")?.failed, "Configured provider errors remain selectable");
            service.selectEntry("anthropic@team");
            check(service.selectedId === "anthropic@team", "Backend selects a configured failed account");
            beginBackendRefresh(1);
        } else if (backendPhase === 1) {
            if (!backendRefreshFinished()) return;
            check(service.stale && service.hasReport, "Malformed provider catalog marks the last report stale");
            check(service.availableEntries.length === 4 && service.selectedId === "anthropic@team", "Malformed catalog retains last-good provider rows and selection");
            beginBackendRefresh(2);
        } else if (backendPhase === 2) {
            if (!backendRefreshFinished()) return;
            check(service.stale && service.availableEntries.length === 4, "Failed discovery retains the last-good report");
            check(service.selectedId === "anthropic@team", "Failed discovery preserves selected account");
            beginBackendRefresh(3);
        } else if (backendPhase === 3) {
            if (!backendRefreshFinished()) return;
            check(service.stale && service.refreshError.includes("timed out"), "Timed-out report refresh is shown as stale");
            check(service.availableEntries.length === 4 && service.selectedId === "anthropic@team", "Timed-out report retains last-good rows and selection");
            beginBackendRefresh(4);
        } else if (backendPhase === 4) {
            if (!backendRefreshFinished()) return;
            check(service.stale && service.refreshError.includes("invalid JSON"), "Malformed usage report is shown as stale");
            check(service.availableEntries.length === 4 && service.selectedId === "anthropic@team", "Malformed report retains last-good rows and selection");
            beginBackendRefresh(5);
        } else if (backendPhase === 5) {
            if (!backendRefreshFinished()) return;
            check(!service.stale && service.availableEntries.length === 3, "A fresh report replaces removed provider rows");
            check(service.selectedId === "anthropic@team", "Selected failed account remains available in fresh report");
            service.selectEntry("anthropic@team");
            beginBackendRefresh(6);
        } else if (backendPhase === 6) {
            if (!backendRefreshFinished()) return;
            check(service.stale && service.availableEntries.length === 2, "Usage failure retains the latest report filtered by the new catalog");
            check(service.selectedId === "openai@work", "Selection reconciles when discovery removes the selected account before usage fails");
            backendDone = true;
        }
    }

    function readyEntry(id, displayName, plan, credits, label, value) {
        const metric = {
            label: label,
            percent: 42,
            value: value,
            detail: "Resets soon",
            severity: "low",
            resetAtMs: root.resetAt,
            windowSeconds: 3600,
            elapsedPercent: 18
        };
        const unknownWindowMetric = {
            label: "Lifetime",
            percent: 72,
            value: "72%",
            detail: "No reset metadata",
            severity: "low",
            resetAtMs: null,
            windowSeconds: null,
            elapsedPercent: null
        };
        const sections = [
            {type: "metric", metric: metric},
            {type: "metric", metric: unknownWindowMetric},
            {type: "text", label: "Spend", value: "$1.25"},
            {type: "block", label: "Activity", body: ["Today: 1.2k tokens", "This week: 4.8k tokens"]},
            {type: "spacer"}
        ];
        for (let index = 0; index < 8; index++)
            sections.push({type: "text", label: "History " + index, value: "Usage summary for this period."});
        return {
            id: id,
            displayName: displayName,
            plan: plan,
            error: "",
            failed: false,
            stale: false,
            fetchedAtMs: Date.now(),
            credits: credits,
            metrics: [metric, unknownWindowMetric],
            sections: sections
        };
    }

    function failedEntry(id, displayName, error) {
        return {
            id: id,
            displayName: displayName,
            plan: "",
            error: error,
            failed: true,
            stale: false,
            fetchedAtMs: null,
            credits: "",
            metrics: [],
            sections: []
        };
    }

    function testView() {
        const picker = named(view, "ai-usage-provider-picker");
        const loading = named(view, "ai-usage-loading");
        check(loading && loading.visible, "Initial provider refresh shows loading");
        check(!picker || !picker.visible, "Zero providers hide the picker");
        refreshStart = service.refreshCount;
        phase = 1;
    }

    function tick() {
        if (phase === 0) {
            testView();
        } else if (phase === 1) {
            service.loading = false;
            service.hasReport = true;
            service.availableEntries = [];
            check(named(view, "ai-usage-empty").visible, "An empty successful report shows the no-provider state");
            check(!named(view, "ai-usage-provider-picker").visible, "No provider selector is shown for zero rows");
            phase = 2;
        } else if (phase === 2) {
            service.availableEntries = [readyEntry("openai@work", "OpenAI · work", "Team", "$4.00", "Session", "42%")];
            service.selectedId = "openai@work";
            phase = 22;
        } else if (phase === 22) {
            if (view.providerTransitionRunning || view.displayedEntry?.id !== service.selectedId) return;
            check(!named(view, "ai-usage-provider-picker").visible, "A single account opens directly without a picker");
            check(containsText(view, "OpenAI · work") && containsText(view, "Team"), "Single provider identity and plan are shown");
            check(containsText(named(view, "ai-usage-metrics"), "Session"), "Fresh quota metric is shown");
            check(containsText(named(view, "ai-usage-metrics"), "42%"), "Fresh quota value is shown");
            check(containsText(named(view, "ai-usage-credits"), "$4.00"), "Credits are shown");
            check(containsText(named(view, "ai-usage-metrics"), "$1.25"), "Text sections are shown");
            check(containsText(named(view, "ai-usage-metrics"), "Today: 1.2k tokens"), "Block sections are shown: " + textList(named(view, "ai-usage-metrics"), []).join(" | "));
            check(containsText(named(view, "ai-usage-metrics"), "Resets in"), "Metric reset countdown is shown");
            check(containsText(named(view, "ai-usage-metrics"), "25% · 17% over pace"), "Reset window derives elapsed percentage from the countdown");
            check(containsText(named(view, "ai-usage-metrics"), "No reset metadata"), "Unknown metric metadata keeps its descriptive detail");
            check(countVisibleText(named(view, "ai-usage-metrics"), "Window elapsed", true) === 1, "Unknown window metadata does not fabricate an elapsed or pace row");
            const details = named(view, "ai-usage-details-scroll");
            check(details.height <= 440 && details.contentHeight > details.height, "Long reports use the scroll cap: " + details.height + "/" + details.contentHeight);
            capture(view, "ISLAND_AI_USAGE_SINGLE_SCREENSHOT", () => singleCaptured = true);
            phase = 21;
        } else if (phase === 21) {
            if (!singleCaptured) return;
            service.availableEntries = [
                readyEntry("openai@work", "OpenAI · work", "Team", "$4.00", "Session", "42%"),
                readyEntry("openai@personal", "OpenAI · personal", "Plus", "$2.00", "Weekly", "18%"),
                failedEntry("anthropic@work", "Anthropic · work", "Authentication required")
            ];
            service.selectedId = "openai@work";
            phase = 3;
        } else if (phase === 3) {
            check(named(view, "ai-usage-provider-picker").visible, "Multiple named accounts show a provider selector");
            capture(view, "ISLAND_AI_USAGE_MULTI_SCREENSHOT", () => multiCaptured = true);
            phase = 31;
        } else if (phase === 31) {
            if (!multiCaptured) return;
            const picker = named(view, "ai-usage-provider-picker");
            picker.popup.open();
            phase = 4;
        } else if (phase === 4) {
            const failedChoice = named(named(view, "ai-usage-provider-picker").popup.contentItem, "ai-usage-provider-entry-anthropic@work");
            check(failedChoice, "Configured failed provider remains selectable");
            click(failedChoice);
            check(service.selectedId === "anthropic@work", "Provider selection updates service account");
            phase = 41;
        } else if (phase === 41) {
            if (view.providerTransitionRunning || view.displayedEntry?.id !== "anthropic@work") return;
            check(named(view, "ai-usage-error").visible && containsText(named(view, "ai-usage-error"), "Authentication required"), "Selected provider failure is visible");
            phase = 5;
        } else if (phase === 5) {
            service.selectEntry("openai@personal");
            check(service.selectedId === "openai@personal", "Named account selection is accepted");
            phase = 51;
        } else if (phase === 51) {
            if (view.providerTransitionRunning || view.displayedEntry?.id !== "openai@personal") return;
            check(containsText(view, "OpenAI · personal") && containsText(named(view, "ai-usage-metrics"), "Weekly"), "Selected named account detail updates");
            service.stale = true;
            service.refreshError = "Could not refresh provider usage.";
            check(named(view, "ai-usage-error").visible && containsText(named(view, "ai-usage-error"), "Could not refresh"), "Refresh failure is visible alongside cached report");
            const refresh = named(view, "ai-usage-refresh");
            click(refresh);
            check(service.refreshCount === refreshStart + 1, "Manual refresh reaches the service");
            uiDone = true;
        }
    }

    QtObject {
        id: service
        property var availableEntries: []
        property string selectedId: ""
        readonly property var selectedEntry: availableEntries.find(entry => entry.id === selectedId) ?? null
        property bool hasReport: false
        property bool loading: true
        property bool stale: false
        property string refreshError: ""
        property double clockNow: Date.now()
        property int refreshCount: 0
        function refresh() { refreshCount++; }
        function selectEntry(id) {
            if (availableEntries.some(entry => entry.id === id)) selectedId = id;
        }
    }

    TestEvent { id: input }

    AIUsageView {
        usageService: AIUsageService
        visible: false
    }

    FloatingWindow {
        visible: true
        implicitWidth: 720
        implicitHeight: 640
        AIUsageView { id: view; usageService: service }
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            try {
                root.tickBackend();
                if (!root.uiDone) root.tick();
                if (root.uiDone && root.backendDone) {
                    console.log("PASS: AI Usage UI and singleton provider regression states");
                    Qt.quit();
                }
            }
            catch (error) { console.error("FAIL: " + (error.stack ?? error)); Qt.quit(); }
        }
    }
}
