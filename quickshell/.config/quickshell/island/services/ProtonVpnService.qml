pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "ProtonVpnParser.js" as Parser

// Proton VPN through the official `protonvpn` CLI, with NetworkManager as the source of truth for
// whether the tunnel is up. Nothing runs while no panel holds the service (see acquirePanel).
Singleton {
    id: root

    readonly property string cliPath: Quickshell.env("ISLAND_PROTONVPN_CLI") || "/usr/bin/protonvpn"
    readonly property string nmcliPath: Quickshell.env("ISLAND_PROTONVPN_NMCLI") || "/usr/bin/nmcli"
    readonly property string terminalPath: Quickshell.env("ISLAND_PROTONVPN_TERMINAL") || "/usr/bin/kitty"

    property int panelUsers: 0
    readonly property bool enabled: panelUsers > 0

    property bool installed: true
    property bool accountKnown: false
    property bool signedIn: false
    property bool linkKnown: false
    property bool connected: false
    property bool connecting: false
    property string server: ""
    property string location: ""
    property string device: ""
    property var details: []
    property var countries: []
    property var configuration: ({})
    property string linkError: ""
    property string lastError: ""
    property string actionError: ""
    property string pendingAction: ""
    property string currentJob: ""
    property var jobs: []
    property double actionFinishedAt: 0
    property double linkStartedAt: 0

    readonly property bool busy: pendingAction.length > 0
    readonly property bool refreshing: currentJob.length > 0 || jobs.length > 0
    readonly property string error: [linkError, actionError || lastError].filter(value => value.length > 0).join("\n")
    readonly property string title: busy ? pendingAction
        : !linkKnown ? "Checking connection…"
        : connected ? "Protected" : "Not connected"
    readonly property string subtitle: connected
        ? [server, location].filter(value => value.length > 0).join(" · ")
        : !installed ? "Install proton-vpn-cli to get started"
        : accountKnown && !signedIn ? "Sign in to connect"
        : "Connect to protect your traffic"

    function acquirePanel() { panelUsers++; }
    function releasePanel() { panelUsers = Math.max(0, panelUsers - 1); }

    function action(label, args) {
        if (busy || !installed) return;
        pendingAction = label;
        lastError = "";
        actionError = "";
        jobs = [];
        enqueue("action", args);
    }

    function connect(country, random) {
        if (!signedIn || !accountKnown) return;
        if (country && !countries.some(entry => entry.code === country)) return;
        const args = ["connect"];
        if (country) args.push("--country", country);
        if (random) args.push("--random");
        action("Connecting…", args);
    }

    function disconnect() {
        if (connected) action("Disconnecting…", ["disconnect"]);
    }

    function setConfig(key, value) {
        const allowed = { "kill-switch": ["off", "standard"] };
        if (!signedIn || !allowed[key] || !allowed[key].includes(value)) return;
        action("Updating protection…", ["config", "set", key, value]);
    }

    function signIn(username) {
        const name = String(username).trim();
        if (busy || !installed || !/^[A-Za-z0-9._+@-]{1,254}$/.test(name)) return;
        action("Signing in…", ["signin", name]);
    }

    function enqueue(name, args) {
        if (currentJob === name || jobs.some(job => job.name === name)) return;
        jobs = jobs.concat([{ name: name, args: args }]);
        runNext();
    }

    function runNext() {
        if (currentJob || jobs.length === 0) return;
        const job = jobs[0];
        jobs = jobs.slice(1);
        // Proton's CLI shares an unlocked cache, so probes and actions take turns.
        currentJob = job.name;
        if (job.name === "action" && job.args[0] === "signin") {
            // Password and 2FA prompts belong to Proton's own terminal flow.
            cliProcess.command = [terminalPath, cliPath].concat(job.args);
        } else {
            const timeout = job.name === "action" ? "90s" : "20s";
            cliProcess.command = ["/usr/bin/timeout", "--signal=TERM", "--kill-after=1s", timeout, cliPath].concat(job.args);
        }
        cliProcess.running = true;
    }

    function finishJob(exitCode, output, errors) {
        const job = currentJob;
        currentJob = "";
        if (job === "action") {
            pendingAction = "";
            actionFinishedAt = Date.now();
            if (exitCode !== 0) actionError = Parser.error(exitCode, output + "\n" + errors);
            refresh();
        } else if (job === "status") {
            finishStatus(exitCode, output, errors);
        } else {
            finishProbe(job, exitCode, output, errors);
        }
        runNext();
    }

    function finishProbe(job, exitCode, output, errors) {
        if (exitCode === 0) {
            if (job === "account") {
                accountKnown = true;
                signedIn = Parser.signedIn(output);
            } else if (job === "config") {
                configuration = Parser.config(output);
            } else if (job === "countries") {
                countries = Parser.countries(output);
            }
            return;
        }
        if (job === "account") {
            accountKnown = false;
            signedIn = false;
        } else if (job === "config") {
            configuration = {};
        }
        lastError = Parser.error(exitCode, output + "\n" + errors);
    }

    function finishStatus(exitCode, output, errors) {
        const status = Parser.status(output);
        installed = exitCode !== 127;
        if (exitCode === 0 && status.valid) {
            lastError = busy ? lastError : "";
            connecting = status.connecting;
            const matchesLink = status.connected && connected && status.server === server;
            location = matchesLink ? status.location : "";
            details = matchesLink ? status.details : [];
        } else {
            lastError = Parser.error(exitCode, output + "\n" + errors);
        }
    }

    function refresh() {
        if (!enabled || busy) return;
        watchLink();
        enqueue("status", ["status"]);
        enqueue("account", ["info"]);
        enqueue("config", ["config", "list"]);
        if (countries.length === 0) enqueue("countries", ["countries", "list"]);
    }

    function watchLink() {
        if (!enabled || linkProcess.running) return;
        linkStartedAt = Date.now();
        linkProcess.running = true;
    }

    onPanelUsersChanged: {
        if (enabled) refresh();
        else jobs = jobs.filter(job => job.name === "action");
    }

    Process {
        id: linkProcess
        command: ["/usr/bin/timeout", "--kill-after=1s", "5s", root.nmcliPath, "-t", "-f", "NAME,TYPE,DEVICE,STATE", "connection", "show", "--active"]
        stderr: StdioCollector {}
        stdout: StdioCollector { id: linkOutput }
        onExited: function(exitCode) {
            // An action that finished while this read was in flight makes the result stale.
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
        stderr: StdioCollector { id: cliErrors }
        stdout: StdioCollector { id: cliOutput }
        onExited: function(exitCode) { root.finishJob(exitCode, cliOutput.text, cliErrors.text); }
    }

    Timer {
        interval: 4000
        repeat: true
        running: root.enabled
        onTriggered: root.watchLink()
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.enabled
        onTriggered: root.refresh()
    }
}
