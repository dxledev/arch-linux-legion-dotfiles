pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../services"

Singleton {

    id: root

    // =========================================================
    // CONFIG
    // =========================================================

    readonly property string nmcliBin: Quickshell.env("ISLAND_NMCLI_BIN") || "nmcli"


    // =========================================================
    // STATE
    // =========================================================

    property bool connected: false
    property bool radioEnabled: true

    property int strength: 0
    property string ssid: ""

    // Wi-Fi device name from `nmcli dev`, used by disconnect().
    property string wifiIface: ""

    // Scanning and connecting are derived from the processes that run them.
    readonly property bool scanning: rescanProc.running || listReader.running
    readonly property bool connecting: connectProc.running

    property string busySsid: ""
    property string lastError: ""

    // Visible networks: { ssid, signal, security, secured, active, saved }
    property var networks: []
    property var savedSsids: []

    // Number of UI consumers that want the network list refreshed.
    property int listActive: 0

    // Raw parsed rows from the last list, before saved flags are applied.
    property var scannedRows: []

    property string icon: "󰤮"

    property string subtitle:
        !radioEnabled
            ? "Off"
            : (connecting
                ? "Connecting..."
                : (connected
                    ? ssid
                    : "Disconnected"))

    property url svgIcon: !connected
        ? Qt.resolvedUrl("../assets/icons/wifi-off.svg")
        : Qt.resolvedUrl("../assets/icons/wifi.svg")

    signal passwordRequired(string ssid)


    // =========================================================
    // NOTIFICATION STATE
    // =========================================================

    // Used so Luci doesn't send a notification when
    // the service first starts and reads the current state.
    property bool initialized: false

    property bool previousConnected: false
    property string previousSsid: ""


    // =========================================================
    // HELPERS
    // =========================================================

    // Splits an nmcli terse (-t) line on unescaped colons.
    // nmcli escapes ':' as '\:' and '\' as '\\' inside fields.
    function splitTerse(line) {

        const fields = []
        let current = ""
        let escaped = false

        for (const ch of line) {

            if (escaped) {
                current += ch
                escaped = false
            } else if (ch === "\\") {
                escaped = true
            } else if (ch === ":") {
                fields.push(current)
                current = ""
            } else {
                current += ch
            }
        }

        fields.push(current)

        return fields
    }

    function nonEmptyLines(text) {

        return text.split("\n").filter(line => line.length > 0)
    }

    function firstErrorLine(text) {

        const line = nonEmptyLines(text.trim())[0] ?? ""

        return line.replace(/^Error:\s*/, "").trim()
    }

    function queueRead(proc) {

        if (proc.running)
            proc.pending = true
        else
            proc.running = true
    }

    function buildNetworks() {

        const byName = new Map()

        for (const row of scannedRows) {

            const existing = byName.get(row.ssid)

            if (!existing) {
                byName.set(row.ssid, row)
                continue
            }

            // Active wins, otherwise keep the strongest signal.
            if (row.active && !existing.active)
                byName.set(row.ssid, row)
            else if (row.active === existing.active && row.signal > existing.signal)
                byName.set(row.ssid, row)
        }

        const result = []

        for (const row of byName.values()) {

            result.push({
                ssid: row.ssid,
                signal: row.signal,
                security: row.security,
                secured: row.security !== "",
                active: row.active,
                saved: savedSsids.indexOf(row.ssid) >= 0
            })
        }

        result.sort((a, b) => {

            if (a.active !== b.active)
                return a.active ? -1 : 1

            if (a.signal !== b.signal)
                return b.signal - a.signal

            return a.ssid.localeCompare(b.ssid)
        })

        return result
    }


    // =========================================================
    // WIFI STATUS READER
    // =========================================================

    Process {

        id: wifiReader

        property bool pending: false

        command: [
            root.nmcliBin,
            "-t",
            "-e",
            "yes",
            "-f",
            "ACTIVE,SIGNAL,SSID",
            "dev",
            "wifi"
        ]

        stdout: StdioCollector {

            onStreamFinished: {

                const line = root.nonEmptyLines(text).find(
                    row => root.splitTerse(row)[0] === "yes"
                )

                // -------------------------------------------------
                // Disconnected
                // -------------------------------------------------

                if (!line) {

                    root.connected = false
                    root.strength = 0
                    root.ssid = ""

                    root.updateIcon()
                    root.handleStateChange()

                    return
                }


                // -------------------------------------------------
                // Connected
                // -------------------------------------------------

                const parts = root.splitTerse(line)

                root.connected = true

                root.strength = Number(parts[1]) || 0
                root.ssid = parts.slice(2).join(":")

                root.updateIcon()
                root.handleStateChange()
            }
        }

        onExited: {

            if (pending) {
                pending = false
                running = true
            }
        }
    }


    // =========================================================
    // RADIO STATUS READER
    // =========================================================

    Process {

        id: radioReader

        property bool pending: false

        command: [
            root.nmcliBin,
            "-t",
            "radio",
            "wifi"
        ]

        stdout: StdioCollector {

            onStreamFinished: {

                root.radioEnabled = text.trim() === "enabled"
            }
        }

        onExited: {

            if (pending) {
                pending = false
                running = true
            }
        }
    }


    // =========================================================
    // DEVICE READER
    // =========================================================

    Process {

        id: deviceReader

        property bool pending: false

        command: [
            root.nmcliBin,
            "-t",
            "-f",
            "DEVICE,TYPE",
            "dev"
        ]

        stdout: StdioCollector {

            onStreamFinished: {

                let iface = ""

                for (const row of root.nonEmptyLines(text)) {

                    const parts = root.splitTerse(row)

                    if (parts[1] === "wifi") {
                        iface = parts[0]
                        break
                    }
                }

                root.wifiIface = iface
            }
        }

        onExited: {

            if (pending) {
                pending = false
                running = true
            }
        }
    }


    // =========================================================
    // NETWORK LIST
    // =========================================================

    Process {

        id: listReader

        property bool pending: false

        command: [
            root.nmcliBin,
            "-t",
            "-e",
            "yes",
            "-f",
            "IN-USE,SIGNAL,SECURITY,SSID",
            "dev",
            "wifi",
            "list",
            "--rescan",
            "no"
        ]

        stdout: StdioCollector {

            onStreamFinished: {

                const rows = []

                for (const line of root.nonEmptyLines(text)) {

                    const parts = root.splitTerse(line)
                    const name = parts.slice(3).join(":")

                    if (name === "")
                        continue

                    let security = parts[2] ?? ""

                    if (security === "--")
                        security = ""

                    rows.push({
                        ssid: name,
                        signal: Math.max(0, Math.min(100, parseInt(parts[1], 10) || 0)),
                        security: security,
                        active: parts[0] === "*"
                    })
                }

                root.scannedRows = rows
                root.networks = root.buildNetworks()
            }
        }

        onExited: {

            if (pending) {
                pending = false
                running = true
            }
        }
    }


    // =========================================================
    // SAVED PROFILES
    // =========================================================

    Process {

        id: savedReader

        property bool pending: false

        command: [
            root.nmcliBin,
            "-t",
            "-f",
            "NAME,TYPE",
            "connection",
            "show"
        ]

        stdout: StdioCollector {

            onStreamFinished: {

                const names = []

                for (const line of root.nonEmptyLines(text)) {

                    const parts = root.splitTerse(line)

                    if (parts[parts.length - 1] !== "802-11-wireless")
                        continue

                    names.push(parts.slice(0, -1).join(":"))
                }

                root.savedSsids = names
                root.networks = root.buildNetworks()
            }
        }

        onExited: {

            if (pending) {
                pending = false
                running = true
            }
        }
    }


    // =========================================================
    // RESCAN
    // =========================================================

    Process {

        id: rescanProc

        command: [
            root.nmcliBin,
            "dev",
            "wifi",
            "rescan"
        ]

        // Errors when rescanned too recently; the list still works.
        onExited: root.refreshNetworks()
    }


    // =========================================================
    // CONNECT
    // =========================================================

    Process {

        id: connectProc

        property string targetSsid: ""
        property bool passwordSupplied: false

        stderr: StdioCollector {
            id: connectErrors
        }

        onExited: function(code) {

            const ssidName = connectProc.targetSsid
            const errorText = connectErrors.text.trim()

            root.busySsid = ""

            if (code !== 0) {

                const needsSecret = /Secrets were required|802-11-wireless-security\.psk|property is missing|No secrets/.test(errorText)

                if (needsSecret) {

                    root.lastError = connectProc.passwordSupplied
                        ? "Incorrect password"
                        : "Password required"

                    root.passwordRequired(ssidName)

                } else {

                    root.lastError = root.firstErrorLine(errorText) || "Connection failed"
                }

            } else {

                root.lastError = ""
            }

            root.update()
            root.refreshSaved()
            root.refreshNetworks()
        }
    }


    // =========================================================
    // DISCONNECT
    // =========================================================

    Process {

        id: disconnectProc

        stderr: StdioCollector {
            id: disconnectErrors
        }

        onExited: function(code) {

            if (code !== 0)
                root.lastError = root.firstErrorLine(disconnectErrors.text) || "Disconnect failed"

            root.update()
            root.refreshNetworks()
        }
    }


    // =========================================================
    // FORGET
    // =========================================================

    Process {

        id: forgetProc

        property string targetSsid: ""

        stderr: StdioCollector {
            id: forgetErrors
        }

        onExited: function(code) {

            root.busySsid = ""

            if (code !== 0)
                root.lastError = root.firstErrorLine(forgetErrors.text) || "Could not forget network"

            root.refreshSaved()
            root.refreshNetworks()
            root.update()
        }
    }


    // =========================================================
    // WIFI RADIO
    // =========================================================

    Process {

        id: radioToggle

        stderr: StdioCollector {
            id: radioErrors
        }

        onExited: function(code) {

            if (code !== 0)
                root.lastError = root.firstErrorLine(radioErrors.text) || "Could not change Wi-Fi radio"

            root.update()
        }
    }


    // =========================================================
    // STATE CHANGE DETECTION
    // =========================================================

    function handleStateChange() {

        // First reading after Luci starts.
        // Don't send a notification.
        if (!root.initialized) {

            root.previousConnected =
                root.connected

            root.previousSsid =
                root.ssid

            root.initialized = true

            console.log(
                "Wi-Fi initial state:",
                root.connected
                    ? root.ssid
                    : "Disconnected"
            )

            return
        }


        // -------------------------------------------------
        // Disconnected → Connected
        // -------------------------------------------------

        if (
            !root.previousConnected &&
            root.connected
        ) {

            console.log(
                "Wi-Fi connected:",
                root.ssid
            )

            NotificationService.send(
                "Luci",
                "Wi-Fi connected",
                root.ssid
            )
        }


        // -------------------------------------------------
        // Connected → Disconnected
        // -------------------------------------------------

        else if (
            root.previousConnected &&
            !root.connected
        ) {

            console.log(
                "Wi-Fi disconnected"
            )

            NotificationService.send(
                "Luci",
                "Wi-Fi disconnected",
                ""
            )
        }


        // -------------------------------------------------
        // Connected → Different network
        // -------------------------------------------------

        else if (
            root.previousConnected &&
            root.connected &&
            root.previousSsid !== root.ssid
        ) {

            console.log(
                "Wi-Fi network changed:",
                root.previousSsid,
                "→",
                root.ssid
            )

            NotificationService.send(
                "Luci",
                "Wi-Fi network changed",
                root.ssid
            )
        }


        // -------------------------------------------------
        // Save current state
        // -------------------------------------------------

        root.previousConnected =
            root.connected

        root.previousSsid =
            root.ssid
    }


    // =========================================================
    // POLLING
    // =========================================================

    Timer {

        interval: 5000

        running: true
        repeat: true

        onTriggered: {
            root.update()
        }
    }

    Timer {

        interval: 10000

        running: root.listActive > 0
        repeat: true

        onTriggered: {
            root.refreshNetworks()
        }
    }


    // =========================================================
    // UPDATE
    // =========================================================

    function update() {

        queueRead(wifiReader)
        queueRead(radioReader)
        queueRead(deviceReader)
    }

    function refreshNetworks() {

        queueRead(listReader)
    }

    function refreshSaved() {

        queueRead(savedReader)
    }


    // =========================================================
    // LIST USAGE
    // =========================================================

    function acquireList() {

        listActive++

        if (listActive === 1) {

            scan()
            refreshSaved()
        }
    }

    function releaseList() {

        listActive = Math.max(0, listActive - 1)
    }


    // =========================================================
    // SCAN
    // =========================================================

    function scan() {

        // A scan is already running; its list will follow.
        if (rescanProc.running)
            return

        rescanProc.running = true
    }


    // =========================================================
    // CONNECT / DISCONNECT / FORGET
    // =========================================================

    function connectTo(ssid, password) {

        if (busySsid !== "" || connectProc.running)
            return

        const pw = password ?? ""
        const isSaved = savedSsids.indexOf(ssid) >= 0

        let args

        if (isSaved && pw === "") {

            args = [
                root.nmcliBin,
                "--wait",
                "20",
                "connection",
                "up",
                "id",
                ssid
            ]

        } else {

            args = [
                root.nmcliBin,
                "--wait",
                "20",
                "dev",
                "wifi",
                "connect",
                ssid
            ]

            if (pw !== "")
                args.push("password", pw)
        }

        lastError = ""
        busySsid = ssid

        connectProc.targetSsid = ssid
        connectProc.passwordSupplied = pw !== ""
        connectProc.command = args
        connectProc.running = true
    }

    function disconnect() {

        if (disconnectProc.running)
            return

        if (wifiIface === "") {

            lastError = "No Wi-Fi device found"

            return
        }

        lastError = ""

        disconnectProc.command = [
            root.nmcliBin,
            "dev",
            "disconnect",
            wifiIface
        ]

        disconnectProc.running = true
    }

    function forget(ssid) {

        if (busySsid !== "" || forgetProc.running)
            return

        lastError = ""
        busySsid = ssid

        forgetProc.targetSsid = ssid
        forgetProc.command = [
            root.nmcliBin,
            "connection",
            "delete",
            "id",
            ssid
        ]

        forgetProc.running = true
    }


    // =========================================================
    // TOGGLE WIFI
    // =========================================================

    function setRadioEnabled(enabled) {

        if (radioToggle.running)
            return

        lastError = ""
        radioEnabled = enabled

        radioToggle.command = [
            root.nmcliBin,
            "radio",
            "wifi",
            enabled ? "on" : "off"
        ]

        radioToggle.running = true
    }

    function toggle() {

        setRadioEnabled(!radioEnabled)
    }


    // =========================================================
    // ICON
    // =========================================================

    function updateIcon() {

        if (!connected) {

            icon = "󰤮"

            return
        }


        if (strength >= 80)
            icon = "󰤨"

        else if (strength >= 60)
            icon = "󰤥"

        else if (strength >= 40)
            icon = "󰤢"

        else if (strength >= 20)
            icon = "󰤟"

        else
            icon = "󰤯"
    }


    // =========================================================
    // STARTUP
    // =========================================================

    Component.onCompleted: {

        console.log(
            "WifiService loaded"
        )

        update()
        refreshSaved()
    }
}
