pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import "../core"
import "../services"
import "../styles"

FocusScope {
    id: root
    implicitWidth: 520
    implicitHeight: content.implicitHeight + 44
    focus: true

    readonly property bool available: BluetoothService.available
    readonly property bool bluetoothOn: BluetoothService.enabled
    readonly property bool scanning: BluetoothService.discovering
    readonly property bool discoverable: BluetoothService.discoverable
    readonly property string busyAddress: BluetoothService.busyAddress
    readonly property string lastError: BluetoothService.lastError

    // Flat list of { kind: "header", title } and { kind: "device", device } rows.
    readonly property var rows: buildRows(
        BluetoothService.connectedDevices,
        BluetoothService.pairedDevices,
        BluetoothService.availableDevices)

    property real spinAngle: 0

    function buildRows(connectedList, pairedList, availableList) {
        const out = [];
        const addSection = (title, list) => {
            if (list.length === 0)
                return;
            out.push({ kind: "header", title: title });
            for (const device of list)
                out.push({ kind: "device", device: device });
        };
        addSection("Connected", connectedList);
        addSection("Paired", pairedList);
        addSection("Available", availableList);
        return out;
    }

    function statusTitle() {
        if (!root.available)
            return "No adapter";
        if (!root.bluetoothOn)
            return "Bluetooth off";
        if (BluetoothService.connected)
            return BluetoothService.deviceName;
        return "Bluetooth on";
    }

    function statusDetail() {
        if (!root.available)
            return "Connect a Bluetooth adapter";
        if (!root.bluetoothOn)
            return "Turn Bluetooth on to see devices";

        const parts = [];
        if (BluetoothService.adapterName.length > 0)
            parts.push(BluetoothService.adapterName);
        const count = BluetoothService.connectedDevices.length;
        if (count > 0)
            parts.push(count + " connected");
        if (root.scanning)
            parts.push("Scanning…");
        return parts.length > 0 ? parts.join(" · ") : "Choose a device below";
    }

    function activate(device) {
        if (device.connected)
            BluetoothService.disconnectDevice(device);
        else
            BluetoothService.connectDevice(device);
    }

    // Spins the scan glyph and busy spinners for as long as work is in flight.
    NumberAnimation {
        target: root
        property: "spinAngle"
        running: root.scanning || root.busyAddress !== ""
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 900
    }

    Component.onCompleted: BluetoothService.acquireList()
    Component.onDestruction: BluetoothService.releaseList()

    Keys.onEscapePressed: IslandController.reset()

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 22
        spacing: 18

        PanelHeader {
            Layout.fillWidth: true
            title: "Bluetooth"
            scrollTargets: [deviceList]
            onBack: IslandController.openControlCenter()
        }

        Rectangle {
            id: statusCard
            objectName: "bluetooth-status-card"
            Layout.fillWidth: true
            Layout.preferredHeight: 68
            radius: 22
            color: Theme.surface

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12
                spacing: 12

                SvgIcon {
                    source: BluetoothService.icon
                    size: 22
                    color: BluetoothService.connected ? Theme.accent : Theme.textSecondary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    UiText {
                        Layout.fillWidth: true
                        text: root.statusTitle()
                        color: Theme.textPrimary
                        font.pixelSize: 15
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    UiText {
                        Layout.fillWidth: true
                        text: root.statusDetail()
                        color: Theme.textSecondary
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                IconButton {
                    objectName: "bluetooth-scan-button"
                    iconSource: "../assets/icons/refresh.svg"
                    description: root.scanning ? "Stop scanning" : "Scan for devices"
                    enabled: root.bluetoothOn
                    opacity: enabled ? 1 : 0.5
                    rotation: root.scanning ? root.spinAngle : 0
                    onClicked: BluetoothService.scan()
                }

                IconButton {
                    objectName: "bluetooth-discoverable-button"
                    iconSource: "../assets/icons/eye.svg"
                    iconColor: root.discoverable ? Theme.accent : Theme.textPrimary
                    description: "Visible as " + BluetoothService.adapterName
                    enabled: root.bluetoothOn
                    opacity: enabled ? 1 : 0.5
                    onClicked: BluetoothService.setDiscoverable(!root.discoverable)
                }

                Switch {
                    id: powerSwitch
                    objectName: "bluetooth-power-switch"
                    Accessible.name: "Bluetooth"
                    implicitWidth: 44
                    implicitHeight: 26
                    padding: 0
                    enabled: root.available
                    focusPolicy: Qt.TabFocus
                    Keys.onReturnPressed: toggle()
                    Keys.onEnterPressed: toggle()
                    checked: root.bluetoothOn
                    onToggled: BluetoothService.toggle()

                    indicator: Rectangle {
                        x: powerSwitch.width - width
                        y: (powerSwitch.height - height) / 2
                        width: 44
                        height: 26
                        radius: 13
                        color: powerSwitch.checked ? Theme.accent : Theme.surfaceVariant
                        border.width: powerSwitch.activeFocus ? 2 : 0
                        border.color: Theme.textPrimary
                        Behavior on color { ColorAnimation { duration: Theme.animationFast } }

                        Rectangle {
                            x: powerSwitch.checked ? parent.width - width - 3 : 3
                            y: 3
                            width: 20
                            height: 20
                            radius: 10
                            color: Theme.textPrimary
                            Behavior on x { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
                        }
                    }
                    contentItem: Item {}
                }
            }
        }

        UiText {
            objectName: "bluetooth-error"
            Layout.fillWidth: true
            visible: root.lastError.length > 0
            text: root.lastError
            color: Theme.danger
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        ListView {
            id: deviceList
            objectName: "bluetooth-device-list"
            readonly property bool scrollAnimationRunning: wheelScroll.animating
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(300, Math.max(54, contentHeight))
            model: root.rows
            spacing: 8
            clip: true
            SmoothScroll { id: wheelScroll; scrollTarget: deviceList }
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}

            delegate: Item {
                id: entry
                required property var modelData

                readonly property bool isHeader: modelData.kind === "header"
                readonly property var device: modelData.device ?? null
                readonly property bool busy: device !== null && root.busyAddress !== "" && root.busyAddress === device.address
                readonly property bool paired: device !== null && (device.paired || device.bonded)

                x: 1
                width: deviceList.width - 2
                height: entry.isHeader ? 22 : 54

                // Passive, so hovering the row's own buttons keeps it hovered.
                HoverHandler { id: rowHover }

                UiText {
                    visible: entry.isHeader
                    objectName: "bluetooth-section-label"
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    text: entry.modelData.title ?? ""
                    color: Theme.textMuted
                    font.pixelSize: 11
                    font.bold: true
                }

                Button {
                    id: deviceRow
                    focusPolicy: Qt.TabFocus
                    visible: !entry.isHeader
                    width: parent.width
                    height: 54
                    padding: 12
                    hoverEnabled: true
                    Accessible.name: (entry.device ? BluetoothService.displayName(entry.device) : "") + (entry.device?.connected ? ", connected" : "")
                    onClicked: root.activate(entry.device)

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }

                    contentItem: RowLayout {
                        spacing: 12

                        SvgIcon {
                            source: BluetoothService.deviceIcon(entry.device)
                            size: 20
                            color: entry.device?.connected ? Theme.accent : Theme.textSecondary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            UiText {
                                objectName: "bluetooth-device-name"
                                Layout.fillWidth: true
                                text: BluetoothService.displayName(entry.device)
                                elide: Text.ElideRight
                                font.pixelSize: 13
                                color: Theme.textPrimary
                            }

                            UiText {
                                Layout.fillWidth: true
                                text: BluetoothService.deviceStatus(entry.device)
                                elide: Text.ElideRight
                                font.pixelSize: 11
                                color: entry.busy || entry.device?.connected ? Theme.accent : Theme.textSecondary
                            }
                        }

                        SvgIcon {
                            objectName: "bluetooth-busy-spinner"
                            visible: entry.busy
                            source: "../assets/icons/refresh.svg"
                            size: 14
                            color: Theme.accent
                            rotation: root.spinAngle
                        }

                        TextActionButton {
                            objectName: "bluetooth-trust-button"
                            visible: entry.paired && rowHover.hovered
                            enabled: !entry.busy
                            text: entry.device?.trusted ? "Untrust" : "Trust"
                            onClicked: BluetoothService.setTrusted(entry.device, !entry.device.trusted)
                        }

                        TextActionButton {
                            objectName: "bluetooth-forget-button"
                            visible: entry.paired && !entry.device?.connected && rowHover.hovered
                            enabled: !entry.busy
                            danger: true
                            text: "Forget"
                            onClicked: BluetoothService.forgetDevice(entry.device)
                        }
                    }

                    background: Rectangle {
                        readonly property real outlineWidth: deviceRow.activeFocus ? 2 : 0
                        readonly property color fillColor: deviceRow.down ? Theme.buttonPressed : deviceRow.hovered ? Theme.surfaceVariant : Theme.surface
                        radius: 16
                        antialiasing: true
                        color: outlineWidth > 0 ? Theme.accent : fillColor

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: parent.outlineWidth
                            radius: Math.max(0, parent.radius - parent.outlineWidth)
                            antialiasing: true
                            color: parent.fillColor
                        }
                    }
                }
            }

            UiText {
                objectName: "bluetooth-empty-state"
                anchors.centerIn: parent
                width: parent.width
                visible: deviceList.count === 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: !root.available
                    ? "No Bluetooth adapter found"
                    : !root.bluetoothOn
                        ? "Bluetooth is off\nTurn it on with the switch above"
                        : root.scanning
                            ? "Searching for devices…"
                            : "No devices found"
                color: Theme.textSecondary
                font.pixelSize: 13
            }
        }
    }
}
