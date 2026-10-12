import QtQuick
import Quickshell
import "island"
import "services"

ShellRoot {
    id: root

    property int phase: 0
    property var motionView: null
    property var pickerRow: null
    property var loadingBanner: null
    property var header: null
    property var headerContainer: null
    property var details: null
    property real rowBaseline: -1
    property real headerBaseline: -1
    property real rowDeviation: 0
    property real headerDeviation: 0
    property real fromHeight: 0
    property real targetHeight: 0
    property real shortHeight: 0
    property real longHeight: 0
    property real previousHeight: 0
    property real largestHeightStep: 0
    property int intermediateHeightSamples: 0
    property string heightTrace: ""
    property real animationStartedAt: 0
    property real minimumOpacity: 1
    property int rapidStage: 0
    property real rapidStartedAt: 0
    property real rapidLargestHeightStep: 0
    property real swapOpacity: 1
    property real swapScroll: -1
    property bool swapObserved: false
    property bool heightSampling: false
    property bool rapidHeightSampling: false

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

    function sceneY(item) {
        return item.mapToItem(capsule, 0, 0).y;
    }

    function describeAncestors(item) {
        const details = [];
        for (let current = item; current; current = current.parent) {
            const name = current === capsule ? "Island" : current === capsule.panelArea ? "panelArea" : current.objectName || "<anonymous>";
            details.push(`${name}:local=${Number(current.y).toFixed(1)},scene=${sceneY(current).toFixed(1)},height=${Number(current.height).toFixed(1)},implicit=${Number(current.implicitHeight).toFixed(1)}`);
            if (current === capsule) break;
        }
        return details.join(" <- ");
    }

    function checkHeaderContentsInsidePanel(item) {
        for (const child of item.children ?? []) {
            if (child.visible !== false && child.width > 0 && child.height > 0) {
                const y = sceneY(child);
                check(y >= -0.5 && y + child.height <= capsule.panelHeight + 1,
                    `Visible header control ${child.objectName || "<anonymous>"} is outside the Island panel (${y.toFixed(1)}..${(y + child.height).toFixed(1)} / ${capsule.panelHeight.toFixed(1)})`);
            }
            checkHeaderContentsInsidePanel(child);
        }
    }

    function checkPanelTopGeometry(stage) {
        const headerY = sceneY(headerContainer);
        const rowY = sceneY(pickerRow);
        console.log(`POSITION ${stage}: capsuleY=${sceneY(capsule).toFixed(1)} actualHeight=${capsule.height.toFixed(1)} panelHeight=${capsule.panelHeight.toFixed(1)} headerY=${headerY.toFixed(1)} textY=${sceneY(header).toFixed(1)} rowY=${rowY.toFixed(1)}`);
        check(headerY >= 10 && headerY <= 40,
            `${stage}: AI Usage header starts outside its top inset (${headerY.toFixed(1)}px); ${describeAncestors(headerContainer)}`);
        check(rowY >= 70 && rowY <= 120,
            `${stage}: AI Usage provider row starts outside its expected top position (${rowY.toFixed(1)}px); ${describeAncestors(pickerRow)}`);
        checkHeaderContentsInsidePanel(headerContainer);
    }

    function entry(id, displayName, credits, sectionCount) {
        const sections = [{type: "metric", metric: {
            label: "Session",
            percent: 38,
            value: "38%",
            detail: "Current usage",
            severity: "low",
            resetAtMs: null,
            windowSeconds: null,
            elapsedPercent: null
        }}];
        for (let index = 0; index < sectionCount; index++)
            sections.push({type: "text", label: `Usage window ${index + 1}`, value: "Detailed provider usage totals for this reporting window."});
        return {
            id: id,
            displayName: displayName,
            plan: id === "anthropic@team" ? "Claude Pro" : "Codex Plus",
            error: "",
            failed: false,
            stale: false,
            fetchedAtMs: Date.now(),
            credits: credits,
            metrics: [],
            sections: sections
        };
    }

    function sampleGeometry() {
        if (!motionView || !pickerRow || !header || rowBaseline < 0 || headerBaseline < 0) return;
        const rowY = pickerRow.mapToItem(capsule, 0, 0).y;
        const headerY = header.mapToItem(capsule, 0, 0).y;
        rowDeviation = Math.max(rowDeviation, Math.abs(rowY - rowBaseline));
        headerDeviation = Math.max(headerDeviation, Math.abs(headerY - headerBaseline));
        minimumOpacity = Math.min(minimumOpacity, motionView.providerOpacity);
    }

    function recordHeight() {
        if (!heightSampling) return;
        targetHeight = motionView?.implicitHeight ?? targetHeight;
        const height = capsule.panelHeight;
        heightTrace += `${height.toFixed(1)},`;
        const step = Math.abs(height - previousHeight);
        largestHeightStep = Math.max(largestHeightStep, step);
        if (rapidHeightSampling) rapidLargestHeightStep = Math.max(rapidLargestHeightStep, step);

        if (!rapidHeightSampling && targetHeight > 0) {
            if (targetHeight > fromHeight && height + 1 < previousHeight)
                check(false, "Island height reversed while expanding for the longer report");
            if (targetHeight < fromHeight && height - 1 > previousHeight)
                check(false, "Island height reversed while shrinking for the longer report");
            if (Math.abs(height - fromHeight) > 2 && Math.abs(height - targetHeight) > 2)
                intermediateHeightSamples++;
        }
        previousHeight = height;
    }

    function switchTo(entryId) {
        motionService.selectEntry(entryId);
        animationStartedAt = Date.now();
        fromHeight = capsule.panelHeight;
        targetHeight = 0;
        previousHeight = fromHeight;
        largestHeightStep = 0;
        intermediateHeightSamples = 0;
        heightTrace = "";
        minimumOpacity = 1;
        heightSampling = true;
        rapidHeightSampling = false;
    }

    function tick() {
        sampleGeometry();

        if (phase === 0) {
            if (!ThemeService.ready || capsule.mode !== IslandState.aiUsageMode) return;
            const compactExpand = named(capsule, "compact-expand-button");
            check(compactExpand && !compactExpand.visible && !compactExpand.enabled,
                "Full-panel pointing-hand overlay is hidden in AI Usage mode");
            motionView = named(capsule, "ai-usage-view");
            if (!motionView) return;
            motionView.usageService = motionService;
            pickerRow = named(motionView, "ai-usage-provider-picker-row");
            header = named(motionView, "panel-title");
            headerContainer = header?.parent?.parent?.parent ?? null;
            loadingBanner = named(motionView, "ai-usage-loading");
            details = named(motionView, "ai-usage-details-scroll");
            check(pickerRow && header && headerContainer && loadingBanner && details, "Island ViewHost exposes the AI Usage motion surfaces");
            phase = 1;
        } else if (phase === 1) {
            motionService.availableEntries = [
                entry("anthropic@team", "Claude · team", "$20.00", 2),
                entry("openai@work", "Codex · work", "$200.00", 12)
            ];
            motionService.selectedId = "anthropic@team";
            phase = 2;
        } else if (phase === 2) {
            if (motionView.providerTransitionRunning || motionView.displayedEntry?.id !== "anthropic@team") return;
            if (Math.abs(capsule.panelHeight - motionView.implicitHeight) > 2) return;
            shortHeight = capsule.panelHeight;
            checkPanelTopGeometry("Initial provider display");
            rowBaseline = pickerRow.mapToItem(capsule, 0, 0).y;
            headerBaseline = header.mapToItem(capsule, 0, 0).y;
            rowDeviation = 0;
            headerDeviation = 0;
            motionService.loading = true;
            phase = 9;
        } else if (phase === 9) {
            if (Math.abs(capsule.panelHeight - motionView.implicitHeight) > 2) return;
            check(loadingBanner.visible, "Refresh loading message appears beneath the provider row");
            check(sceneY(loadingBanner) >= sceneY(pickerRow) + pickerRow.height - 1,
                "Refresh loading message is below the provider row");
            checkPanelTopGeometry("During refresh loading");
            motionService.loading = false;
            phase = 10;
        } else if (phase === 10) {
            if (Math.abs(capsule.panelHeight - motionView.implicitHeight) > 2) return;
            check(!loadingBanner.visible, "Refresh loading message clears after refresh");
            checkPanelTopGeometry("After refresh loading");
            check(rowDeviation <= 1.5 && headerDeviation <= 1.5,
                `Loading visibility moved the header or provider row (${headerDeviation.toFixed(2)}px / ${rowDeviation.toFixed(2)}px)`);
            shortHeight = capsule.panelHeight;
            switchTo("openai@work");
            phase = 3;
        } else if (phase === 3) {
            if (motionView.displayedEntry?.id === "openai@work")
                targetHeight = motionView.implicitHeight;
            if (motionView.providerTransitionRunning || motionView.displayedEntry?.id !== "openai@work") return;
            if (Math.abs(capsule.panelHeight - motionView.implicitHeight) > 2) return;
            longHeight = capsule.panelHeight;
            checkPanelTopGeometry("After provider switch");
            check(longHeight - shortHeight > 70, "Claude and Codex fixtures produce meaningfully different panel heights");
            console.log(`MOTION: row=${rowDeviation.toFixed(2)}px header=${headerDeviation.toFixed(2)}px height=${shortHeight.toFixed(1)}→${longHeight.toFixed(1)}px samples=${heightTrace}`);
            check(intermediateHeightSamples >= 3, `Island height only had ${intermediateHeightSamples} intermediate samples (${fromHeight.toFixed(1)}→${targetHeight.toFixed(1)}, final ${longHeight.toFixed(1)})`);
            check(largestHeightStep < 80, "Island height changes by bounded increments between frames");
            check(Date.now() - animationStartedAt < 600, "Long report resize settles quickly");
            check(minimumOpacity < 0.1 && motionView.providerOpacity > 0.98, "Provider report fades out and back in during the resize");
            check(rowDeviation <= 1.5, `Provider row moved ${rowDeviation.toFixed(2)} px during the resize`);
            check(headerDeviation <= 1.5, `Header moved ${headerDeviation.toFixed(2)} px during the resize`);
            heightSampling = false;
            details.contentY = Math.min(120, details.contentHeight - details.height);
            phase = 4;
        } else if (phase === 4) {
            if (details.contentY < 20) return;
            check(motionView.displayedEntry?.id === "openai@work", "Long Codex report is displayed before rapid reversal");
            rapidStartedAt = Date.now();
            rapidStage = 0;
            rapidLargestHeightStep = 0;
            rapidHeightSampling = true;
            heightSampling = true;
            previousHeight = capsule.panelHeight;
            fromHeight = capsule.panelHeight;
            targetHeight = motionView.implicitHeight;
            swapObserved = false;
            motionService.selectEntry("anthropic@team");
            phase = 5;
        } else if (phase === 5) {
            const elapsed = Date.now() - rapidStartedAt;
            if (rapidStage === 0 && elapsed >= 30) {
                motionService.selectEntry("openai@work");
                rapidStage = 1;
            } else if (rapidStage === 1 && elapsed >= 65) {
                motionService.selectEntry("anthropic@team");
                rapidStage = 2;
            }
            if (rapidStage < 2 || motionView.providerTransitionRunning || motionView.displayedEntry?.id !== "anthropic@team" || !swapObserved) return;
            if (Math.abs(capsule.panelHeight - motionView.implicitHeight) > 2) return;
            check(Date.now() - rapidStartedAt < 600, "Rapid provider reversal settles quickly");
            check(motionService.selectedId === "anthropic@team" && motionView.displayedEntry?.credits === "$20.00", "Latest rapid provider selection wins");
            check(motionView.providerOpacity > 0.98 && motionView.displayedEntry?.id === "anthropic@team", "Rapid swap finishes with the latest report fully visible");
            check(Math.abs(capsule.panelHeight - shortHeight) <= 2, "Rapid reversal returns Island height to the short report target");
            checkPanelTopGeometry("After rapid provider reversal");
            check(rapidLargestHeightStep < 80, "Rapid reversal does not snap Island height");
            check(rowDeviation <= 1.5 && headerDeviation <= 1.5, "Provider row and header stay fixed through rapid reversals");
            check(swapObserved && swapOpacity < 0.1 && swapScroll <= 1,
                `Latest report swap visibility/scroll invariant failed (observed=${swapObserved}, opacity=${swapOpacity.toFixed(2)}, scroll=${swapScroll.toFixed(1)})`);
            heightSampling = false;
            motionView = null;
            IslandState.mode = IslandState.navigationMode;
            phase = 6;
        } else if (phase === 6) {
            if (capsule.mode !== IslandState.navigationMode || !named(capsule, "menu-search")) return;
            IslandState.mode = IslandState.aiUsageMode;
            phase = 7;
        } else if (phase === 7) {
            if (capsule.mode !== IslandState.aiUsageMode) return;
            motionView = named(capsule, "ai-usage-view");
            if (!motionView) return;
            motionView.usageService = motionService;
            pickerRow = named(motionView, "ai-usage-provider-picker-row");
            header = named(motionView, "panel-title");
            headerContainer = header?.parent?.parent?.parent ?? null;
            loadingBanner = named(motionView, "ai-usage-loading");
            details = named(motionView, "ai-usage-details-scroll");
            phase = 8;
        } else if (phase === 8) {
            if (motionView.providerTransitionRunning || motionView.displayedEntry?.id !== motionService.selectedId) return;
            if (Math.abs(capsule.panelHeight - motionView.implicitHeight) > 2) return;
            const compactExpand = named(capsule, "compact-expand-button");
            check(compactExpand && !compactExpand.visible && !compactExpand.enabled,
                "Full-panel pointing-hand overlay remains hidden after AI Usage re-entry");
            checkPanelTopGeometry("After leaving and reopening AI Usage");
            console.log("PASS: Island AI Usage row stability, smooth height motion, rapid selection and hidden scroll reset");
            Qt.quit();
        }
    }

    QtObject {
        id: motionService
        property var availableEntries: []
        property string selectedId: ""
        readonly property var selectedEntry: availableEntries.find(entry => entry.id === selectedId) ?? null
        property bool hasReport: true
        property bool loading: false
        property bool stale: false
        property string refreshError: ""
        property double clockNow: Date.now()
        function refresh() {}
        function selectEntry(id) {
            if (availableEntries.some(entry => entry.id === id)) selectedId = id;
        }
    }

    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 720
        implicitHeight: 820

        Island {
            id: capsule
            monitorActive: true
            monitorName: "ai-usage-motion"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
        }
    }

    Connections {
        target: capsule
        function onPanelHeightChanged() { root.recordHeight(); }
    }

    Connections {
        target: motionView
        function onProviderOpacityChanged() {
            root.minimumOpacity = Math.min(root.minimumOpacity, motionView.providerOpacity);
        }
    }

    Connections {
        target: motionView
        function onDisplayedEntryChanged() {
            if (motionView.displayedEntry?.id !== "anthropic@team" || !motionView.providerTransitionRunning) return;
            Qt.callLater(() => {
                root.swapOpacity = motionView.providerOpacity;
                root.swapScroll = details.contentY;
                root.swapObserved = true;
            });
        }
    }

    Component.onCompleted: {
        IslandState.panelMonitorName = "ai-usage-motion";
        IslandState.mode = IslandState.aiUsageMode;
    }

    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            try {
                root.tick();
            } catch (error) {
                console.error("FAIL: " + String(error) + "\n" + (error.stack ?? ""));
                Qt.quit();
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: {
            console.error("FAIL: Island AI Usage motion test timed out at phase " + root.phase);
            Qt.quit();
        }
    }
}
