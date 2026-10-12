pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    // =========================================================
    // CONFIG
    // =========================================================

    // How long a pair or connect may run before it is reported as failed.
    readonly property int operationTimeout: 20000


    // =========================================================
    // ADAPTER STATE
    // =========================================================

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter // qmllint disable unresolved-type
    readonly property bool available: !!adapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false
    readonly property bool discoverable: adapter?.discoverable ?? false
    readonly property string adapterName: adapter?.name ?? ""

    // Number of UI consumers that want the device list refreshed.
    property int listActive: 0

    // True while this service has turned discovery on for the list consumers.
    property bool autoDiscovery: false


    // =========================================================
    // DEVICES
    // =========================================================

    readonly property var allDevices: Bluetooth.devices?.values ?? [] // qmllint disable unresolved-type

    // Visible devices, sorted: connected, then paired, then the rest.
    readonly property var devices: sortDevices(allDevices.filter(d => isListed(d)))

    // Disjoint partitions of `devices`.
    readonly property var connectedDevices: devices.filter(d => d.connected)
    readonly property var pairedDevices: devices.filter(d => !d.connected && isPaired(d))
    readonly property var availableDevices: devices.filter(d => !d.connected && !isPaired(d))

    readonly property bool connected: connectedDevices.length > 0

    readonly property string deviceName:
        connected ? displayName(connectedDevices[0]) : ""

    readonly property string subtitle:
        !enabled
            ? "Off"
            : connected
                ? (connectedDevices.length > 1
                    ? deviceName + " +" + (connectedDevices.length - 1)
                    : deviceName)
                : "On"

    readonly property url icon:
        !enabled
            ? Qt.resolvedUrl("../assets/icons/bluetooth-off.svg")
            : connected
                ? Qt.resolvedUrl("../assets/icons/bluetooth-connected.svg")
                : Qt.resolvedUrl("../assets/icons/bluetooth.svg")


    // =========================================================
    // OPERATION STATE
    // =========================================================

    // Device with an operation in flight, and which operation it is:
    // "pair", "connect", "disconnect" or "" when idle.
    property var busyDevice: null
    property string busyAction: ""
    readonly property string busyAddress: busyDevice ? busyDevice.address : ""

    // Progress flags for the in-flight operation.
    property bool pairSeen: false
    property bool connectSeen: false

    property string lastError: ""


    // =========================================================
    // HELPERS
    // =========================================================

    function displayName(device) {
        if (!device)
            return "";
        return device.name || device.deviceName || device.address || "Unknown device";
    }

    function isPaired(device) {
        return !!(device && (device.paired || device.bonded));
    }

    // Unnamed devices that are neither paired nor connected are noise.
    function isListed(device) {
        if (!device)
            return false;
        if (isPaired(device) || device.connected)
            return true;
        const name = device.name || device.deviceName || "";
        return name.length > 0 && name !== device.address;
    }

    function sortDevices(list) {
        const rank = d => d.connected ? 0 : (isPaired(d) ? 1 : 2);
        return list.slice().sort((a, b) =>
            (rank(a) - rank(b)) || displayName(a).localeCompare(displayName(b)));
    }

    function deviceIcon(device) {
        const kind = (device?.icon ?? "").toLowerCase();
        let name = "bluetooth.svg";

        if (kind.includes("headset") || kind.includes("headphone"))
            name = "headphones.svg";
        else if (kind.includes("speaker") || kind.includes("audio"))
            name = "speaker.svg";
        else if (kind.includes("keyboard"))
            name = "keyboard.svg";
        else if (kind.includes("mouse"))
            name = "mouse.svg";
        else if (kind.includes("phone"))
            name = "smartphone.svg";
        else if (kind.includes("computer") || kind.includes("laptop"))
            name = "laptop.svg";
        else if (kind.includes("gaming") || kind.includes("gamepad") || kind.includes("joystick"))
            name = "gamepad.svg";

        return Qt.resolvedUrl("../assets/icons/" + name);
    }

    function deviceStatus(device) {
        if (!device)
            return "";

        const busy = busyDevice === device;

        if (device.pairing || (busy && busyAction === "pair"))
            return "Pairing…";

        if (device.state === BluetoothDeviceState.Connecting || (busy && busyAction === "connect" && !device.connected))
            return "Connecting…";

        if (device.state === BluetoothDeviceState.Disconnecting || (busy && busyAction === "disconnect" && device.connected))
            return "Disconnecting…";

        if (device.connected) {
            if (device.batteryAvailable)
                return "Connected · " + Math.round(device.battery * 100) + "%";
            return "Connected";
        }

        return isPaired(device) ? "Paired" : "Not paired";
    }

    function requireReady() {
        if (!available) {
            lastError = "No Bluetooth adapter found";
            return false;
        }
        if (!enabled) {
            lastError = "Turn Bluetooth on first";
            return false;
        }
        return true;
    }

    function clearBusy() {
        busyDevice = null;
        busyAction = "";
        pairSeen = false;
        connectSeen = false;
        operationTimer.stop();
    }

    function succeed() {
        lastError = "";
        clearBusy();
    }

    function fail(message) {
        lastError = message;
        clearBusy();
    }

    // Advances the in-flight pair/connect/disconnect as device signals arrive.
    function handleBusyChange() {
        const device = busyDevice;
        if (!device)
            return;

        if (busyAction === "pair") {
            if (device.pairing) {
                pairSeen = true;
                return;
            }
            if (isPaired(device)) {
                if (device.connected) {
                    succeed();
                } else {
                    busyAction = "connect";
                    device.connect();
                }
            } else if (pairSeen) {
                fail("Pairing with " + displayName(device) + " failed");
            }
            return;
        }

        if (busyAction === "connect") {
            if (device.state === BluetoothDeviceState.Connecting) {
                connectSeen = true;
            } else if (device.state === BluetoothDeviceState.Connected) {
                succeed();
            } else if (device.state === BluetoothDeviceState.Disconnected && connectSeen) {
                fail("Couldn't connect to " + displayName(device));
            }
            return;
        }

        if (busyAction === "disconnect" && device.state === BluetoothDeviceState.Disconnected)
            succeed();
    }

    // Keeps discovery running while list consumers are visible.
    function syncDiscovery() {
        if (!adapter) {
            autoDiscovery = false;
            return;
        }

        if (listActive > 0 && enabled) {
            if (!adapter.discovering) {
                autoDiscovery = true;
                adapter.discovering = true;
            }
        } else if (autoDiscovery) {
            autoDiscovery = false;
            if (enabled && adapter.discovering)
                adapter.discovering = false;
        }
    }


    // =========================================================
    // ACTIONS
    // =========================================================

    function toggle() {
        if (!available) {
            lastError = "No Bluetooth adapter found";
            return;
        }
        adapter.enabled = !adapter.enabled;
        lastError = "";
    }

    function scan() {
        if (!requireReady())
            return;
        adapter.discovering = !adapter.discovering;
        lastError = "";
    }

    function setDiscoverable(value) {
        if (!requireReady())
            return;
        adapter.discoverable = value;
        lastError = "";
    }

    // Connects a device. Unpaired devices are trusted and paired first,
    // then connected once pairing completes.
    function connectDevice(device) {
        if (!device || busyDevice !== null || !requireReady())
            return;
        if (device.connected)
            return;

        busyDevice = device;

        if (isPaired(device)) {
            busyAction = "connect";
            device.connect();
        } else {
            busyAction = "pair";
            device.trusted = true;
            device.pair();
        }

        operationTimer.restart();
    }

    function disconnectDevice(device) {
        if (!device || busyDevice !== null || !device.connected)
            return;

        busyDevice = device;
        busyAction = "disconnect";
        device.disconnect();
        operationTimer.restart();
    }

    function forgetDevice(device) {
        if (!device)
            return;
        if (busyDevice === device)
            clearBusy();
        device.forget();
        lastError = "";
    }

    function setTrusted(device, trusted) {
        if (!device)
            return;
        device.trusted = trusted;
    }

    // Reference-counted discovery for list consumers.
    function acquireList() {
        listActive++;
        syncDiscovery();
    }

    function releaseList() {
        listActive = Math.max(0, listActive - 1);
        syncDiscovery();
    }


    // =========================================================
    // WIRING
    // =========================================================

    Connections {
        target: root.adapter
        ignoreUnknownSignals: true

        function onEnabledChanged() {
            root.syncDiscovery();
        }
    }

    Connections {
        target: root.busyDevice
        ignoreUnknownSignals: true

        function onPairingChanged() { root.handleBusyChange(); }
        function onPairedChanged() { root.handleBusyChange(); }
        function onBondedChanged() { root.handleBusyChange(); }
        function onStateChanged() { root.handleBusyChange(); }
    }

    Timer {
        id: operationTimer
        interval: root.operationTimeout
        repeat: false

        onTriggered: {
            const device = root.busyDevice;
            if (!device)
                return;
            const name = root.displayName(device);
            root.fail(root.busyAction === "pair"
                ? "Pairing with " + name + " timed out"
                : root.busyAction === "disconnect"
                    ? "Disconnecting " + name + " timed out"
                    : "Connecting to " + name + " timed out");
        }
    }

    onAdapterChanged: syncDiscovery()
}
