pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.integration
import "ProtonVpnParser.js" as Parser

Singleton {
    id: root

    property bool accountKnown: false
    property string actionError: ""
    property double actionFinishedAt: 0
    readonly property bool busy: pendingAction.length > 0
    property var configuration: ({})
    property bool connected: false
    property var countries: []
    property string currentJob: ""
    property var details: []
    property string device: ""
    readonly property bool enabled: panelUsers > 0 || Quickshell.screens.some(screen => GlobalConfig.forScreen(screen.name).bar.statusIcons.values.some(entry => entry.id === "protonVpn" && entry.enabled))
    property bool installed: true
    property var jobs: []
    property string lastError: ""
    property string linkError: ""
    property bool linkKnown: false
    property double linkStartedAt: 0
    property string location: ""
    readonly property bool panelOpen: panelUsers > 0
    property int panelUsers: 0
    property string pendingAction: ""
    readonly property bool refreshing: currentJob.length > 0 || jobs.length > 0
    property string server: ""
    readonly property var settings: System.protonVpn
    property bool signedIn: false
    readonly property bool startupReady: StartupState.secretConsumersReady

    function action(label: string, args: list<string>): void {
        if (!startupReady || busy || !installed)
            return;
        pendingAction = label;
        lastError = "";
        actionError = "";
        jobs = [];
        enqueue("action", args);
    }
    function connect(country: string, random: bool): void {
        if (!signedIn || !accountKnown)
            return;
        if (country && !countries.some(entry => entry.code === country))
            return;
        const args = ["connect"];
        if (country)
            args.push("--country", country);
        if (random)
            args.push("--random");
        action("Connecting…", args);
    }
    function disconnect(): void {
        if (connected)
            action("Disconnecting…", ["disconnect"]);
    }
    function enqueue(name: string, args: list<string>): void {
        if (currentJob === name || jobs.some(job => job.name === name))
            return;
        jobs = jobs.concat([
            {
                name: name,
                args: args
            }
        ]);
        runNext();
    }
    function finishJob(exitCode: int, output: string, errors: string): void {
        const job = currentJob;
        currentJob = "";
        if (job === "action") {
            pendingAction = "";
            actionFinishedAt = Date.now();
            if (exitCode !== 0)
                actionError = Parser.error(exitCode, output + "\n" + errors);
            refresh();
        } else if (job === "status") {
            finishStatus(exitCode, output, errors);
        } else {
            finishProbe(job, exitCode, output, errors);
        }
        runNext();
    }
    function finishProbe(job: string, exitCode: int, output: string, errors: string): void {
        if (exitCode === 0) {
            if (job === "account") {
                accountKnown = true;
                signedIn = Parser.signedIn(output);
            } else if (job === "config") {
                configuration = Parser.config(output);
            } else if (job === "countries") {
                countries = Parser.countries(output);
            }
        } else {
            if (job === "account") {
                accountKnown = false;
                signedIn = false;
            } else if (job === "config") {
                configuration = {};
            }
            lastError = Parser.error(exitCode, output + "\n" + errors);
        }
    }
    function finishStatus(exitCode: int, output: string, errors: string): void {
        const status = Parser.status(output);
        installed = exitCode !== 127;
        if (exitCode === 0 && status.valid) {
            lastError = busy ? lastError : "";
            const matchesLink = status.connected && connected && status.server === server;
            location = matchesLink ? status.location : "";
            details = matchesLink ? status.details : [];
        } else {
            lastError = Parser.error(exitCode, output + "\n" + errors);
        }
    }
    function refresh(): void {
        if (!startupReady || !enabled || busy)
            return;
        watchLink();
        enqueue("status", ["status"]);
        if (panelOpen) {
            enqueue("account", ["info"]);
            enqueue("config", ["config", "list"]);
            if (countries.length === 0)
                enqueue("countries", ["countries", "list"]);
        }
    }
    function runNext(): void {
        if (!startupReady || currentJob || jobs.length === 0)
            return;
        const job = jobs[0];
        jobs = jobs.slice(1);
        // Proton's CLI shares an unlocked cache, so probes and actions take turns.
        currentJob = job.name;
        if (job.name === "action" && job.args[0] === "signin") {
            cliProcess.command = [...settings.signInTerminal, settings.cliPath, ...job.args];
            cliProcess.running = true;
            return;
        }
        const timeout = job.name === "action" ? "90s" : "20s";
        cliProcess.command = ["/usr/bin/timeout", "--signal=TERM", "--kill-after=1s", timeout, settings.cliPath, ...job.args];
        cliProcess.running = true;
    }
    function setConfig(key: string, value: string): void {
        const allowed = {
            "kill-switch": ["off", "standard"],
            "netshield": ["off", "malware-only", "malware-ads-trackers"]
        };
        if (!signedIn || !allowed[key]?.includes(value))
            return;
        action("Updating protection…", ["config", "set", key, value]);
    }
    function signIn(username: string): void {
        const name = username.trim();
        if (busy || !installed || !/^[A-Za-z0-9._+@-]{1,254}$/.test(name))
            return;
        action("Signing in…", ["signin", name]);
    }
    function watchLink(): void {
        if (!enabled || linkProcess.running)
            return;
        linkStartedAt = Date.now();
        linkProcess.running = true;
    }

    Component.onCompleted: refresh()
    onStartupReadyChanged: {
        if (startupReady) {
            refresh();
            runNext();
        }
    }
    onEnabledChanged: {
        if (enabled)
            refresh();
        else
            jobs = jobs.filter(job => job.name === "action");
    }
    onPanelOpenChanged: {
        if (panelOpen)
            refresh();
    }

    Process {
        id: linkProcess

        command: ["/usr/bin/timeout", "--kill-after=1s", "5s", root.settings.nmcliPath, "-t", "-f", "NAME,TYPE,DEVICE,STATE", "connection", "show", "--active"]

        stderr: StdioCollector {
        }
        stdout: StdioCollector {
            id: linkOutput
        }

        onExited: exitCode => {
            if (root.linkStartedAt < root.actionFinishedAt) {
                root.watchLink();
                return;
            }
            root.linkKnown = exitCode === 0;
            root.linkError = exitCode === 0 ? "" : "Cannot read NetworkManager. Connection status is unavailable.";
            const link = Parser.link(exitCode === 0 ? linkOutput.text : "");
            if (root.server !== link.server || !link.connected) {
                root.location = "";
                root.details = [];
            }
            root.connected = link.connected;
            root.server = link.server;
            root.device = link.device;
        }
    }
    Process {
        id: cliProcess

        stderr: StdioCollector {
            id: cliErrors
        }
        stdout: StdioCollector {
            id: cliOutput
        }

        onExited: exitCode => root.finishJob(exitCode, cliOutput.text, cliErrors.text)
    }
    Timer {
        interval: Math.max(2000, root.settings.watchIntervalSeconds * 1000)
        repeat: true
        running: root.enabled

        onTriggered: root.watchLink()
    }
    Timer {
        interval: Math.max(5000, (root.panelOpen ? root.settings.panelRefreshIntervalSeconds : root.settings.refreshIntervalSeconds) * 1000)
        repeat: true
        running: root.startupReady && root.enabled

        onTriggered: root.refresh()
    }
}
