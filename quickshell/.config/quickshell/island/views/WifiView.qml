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

    readonly property var networks: radioEnabled ? WifiService.networks : []
    readonly property bool radioEnabled: WifiService.radioEnabled
    readonly property bool scanning: WifiService.scanning
    readonly property string busySsid: WifiService.busySsid
    readonly property string lastError: WifiService.lastError

    // SSID of the network whose inline password prompt is open, or "".
    property string passwordSsid: ""
    property real spinAngle: 0

    function openPasswordFor(ssid) {
        passwordSsid = ssid;
    }

    function closePassword() {
        passwordSsid = "";
        root.forceActiveFocus();
    }

    function activate(network) {
        if (network.active || root.busySsid !== "")
            return;
        if (network.secured && !network.saved) {
            openPasswordFor(network.ssid);
            return;
        }
        WifiService.connectTo(network.ssid, "");
    }

    function submitPassword(ssid, password) {
        if (password.length === 0)
            return;
        WifiService.connectTo(ssid, password);
        closePassword();
    }

    function statusTitle() {
        if (!root.radioEnabled)
            return "Wi-Fi off";
        if (WifiService.connected)
            return WifiService.ssid;
        return "Not connected";
    }

    function statusDetail() {
        if (!root.radioEnabled)
            return "Turn Wi-Fi on to see networks";
        if (WifiService.connected)
            return "Connected · " + WifiService.strength + "%";
        if (WifiService.connecting || root.busySsid !== "")
            return "Connecting…";
        if (root.scanning)
            return "Scanning…";
        return "Choose a network below";
    }

    // Spins the scan glyph for as long as a scan is in flight.
    NumberAnimation {
        target: root
        property: "spinAngle"
        running: root.scanning
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 900
    }

    Component.onCompleted: WifiService.acquireList()
    Component.onDestruction: WifiService.releaseList()

    Connections {
        target: WifiService
        function onPasswordRequired(ssid) {
            root.openPasswordFor(ssid);
        }
    }

    Keys.onEscapePressed: {
        if (root.passwordSsid.length > 0)
            root.closePassword();
        else
            IslandController.openControlCenter();
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 22
        spacing: 18

        PanelHeader {
            Layout.fillWidth: true
            title: "Wi-Fi"
            scrollTargets: [networkList]
            onBack: IslandController.openControlCenter()
        }

        Rectangle {
            id: statusCard
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
                    source: root.radioEnabled
                        ? "../assets/icons/wifi.svg"
                        : "../assets/icons/wifi-off.svg"
                    size: 22
                    color: WifiService.connected ? Theme.accent : Theme.textSecondary
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
                    id: scanButton
                    objectName: "wifi-scan-button"
                    iconSource: "../assets/icons/refresh.svg"
                    description: root.scanning ? "Scanning" : "Scan for networks"
                    enabled: root.radioEnabled && !root.scanning
                    opacity: enabled ? 1 : 0.5
                    rotation: root.scanning ? root.spinAngle : 0
                    onClicked: WifiService.scan()
                }

                IconButton {
                    objectName: "wifi-speedtest-button"
                    visible: WifiService.connected
                    iconSource: "../assets/icons/gauge.svg"
                    description: "Run speed test"
                    onClicked: IslandController.openNetworkSpeedTest()
                }

                IconButton {
                    objectName: "wifi-qr-button"
                    visible: WifiService.connected
                    iconSource: "../assets/icons/qr-code.svg"
                    description: "Share with QR code"
                    onClicked: IslandController.openWifiQr(WifiService.ssid, WifiService.wifiIface)
                }

                Switch {
                    id: radioSwitch
                    objectName: "wifi-radio-switch"
                    Accessible.name: "Wi-Fi radio"
                    implicitWidth: 44
                    implicitHeight: 26
                    padding: 0
                    checked: root.radioEnabled
                    onToggled: WifiService.setRadioEnabled(checked)

                    indicator: Rectangle {
                        x: radioSwitch.width - width
                        y: (radioSwitch.height - height) / 2
                        width: 44
                        height: 26
                        radius: 13
                        color: radioSwitch.checked ? Theme.accent : Theme.surfaceVariant
                        Behavior on color { ColorAnimation { duration: Theme.animationFast } }

                        Rectangle {
                            x: radioSwitch.checked ? parent.width - width - 3 : 3
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
            objectName: "wifi-error"
            Layout.fillWidth: true
            visible: root.lastError.length > 0
            text: root.lastError
            color: Theme.danger
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        ListView {
            id: networkList
            objectName: "wifi-network-list"
            readonly property bool scrollAnimationRunning: wheelScroll.animating
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(300, Math.max(54, contentHeight))
            model: root.networks
            spacing: 8
            clip: true
            SmoothScroll { id: wheelScroll; scrollTarget: networkList }
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}

            delegate: Item {
                id: entry
                required property var modelData

                readonly property string ssid: modelData.ssid ?? ""
                readonly property bool active: !!modelData.active
                readonly property bool saved: !!modelData.saved
                readonly property bool secured: !!modelData.secured
                readonly property bool busy: root.busySsid !== "" && root.busySsid === ssid
                readonly property bool prompting: root.passwordSsid !== "" && root.passwordSsid === ssid
                readonly property string detail: {
                    const parts = [];
                    if (entry.busy) parts.push("Connecting…");
                    else if (entry.active) parts.push("Connected");
                    if (entry.saved) parts.push("Saved");
                    parts.push(entry.secured ? "Secured" : "Open");
                    return parts.join(" · ");
                }

                x: 1
                width: networkList.width - 2
                height: networkRow.height + (prompting ? 48 : 0)

                // Passive, so hovering the row's own buttons keeps it hovered.
                HoverHandler { id: rowHover }

                Button {
                    id: networkRow
                    width: parent.width
                    height: 54
                    padding: 12
                    hoverEnabled: true
                    Accessible.name: entry.ssid + (entry.active ? ", connected" : "")
                    onClicked: root.activate(entry.modelData)

                    contentItem: RowLayout {
                        spacing: 12

                        SvgIcon {
                            source: "../assets/icons/wifi.svg"
                            size: 20
                            color: entry.active ? Theme.accent : Theme.textSecondary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            UiText {
                                Layout.fillWidth: true
                                text: entry.ssid || "Hidden network"
                                elide: Text.ElideRight
                                font.pixelSize: 13
                                color: Theme.textPrimary
                            }

                            UiText {
                                Layout.fillWidth: true
                                text: entry.detail
                                elide: Text.ElideRight
                                font.pixelSize: 11
                                color: entry.busy || entry.active ? Theme.accent : Theme.textSecondary
                            }
                        }

                        TextActionButton {
                            objectName: "wifi-disconnect-button"
                            visible: entry.active
                            enabled: root.busySsid === ""
                            text: "Disconnect"
                            onClicked: WifiService.disconnect()
                        }

                        TextActionButton {
                            objectName: "wifi-forget-button"
                            visible: entry.saved && !entry.active && rowHover.hovered
                            enabled: root.busySsid === ""
                            danger: true
                            text: "Forget"
                            onClicked: WifiService.forget(entry.ssid)
                        }

                        SvgIcon {
                            visible: entry.secured
                            source: "../assets/icons/lock.svg"
                            size: 13
                            color: Theme.textMuted
                        }

                        UiText {
                            text: (modelData.signal ?? 0) + "%"
                            font.pixelSize: 12
                            color: Theme.textSecondary
                        }
                    }

                    background: Rectangle {
                        readonly property real outlineWidth: entry.active || networkRow.activeFocus || entry.prompting ? 2 : 0
                        readonly property color fillColor: networkRow.down ? Theme.buttonPressed : networkRow.hovered ? Theme.surfaceVariant : Theme.surface
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

                Loader {
                    y: networkRow.height + 8
                    width: parent.width
                    height: 40
                    active: entry.prompting
                    sourceComponent: Component {
                        RowLayout {
                            anchors.fill: parent
                            spacing: 8

                            SearchField {
                                id: passwordField
                                objectName: "wifi-password-field"
                                Layout.fillWidth: true
                                placeholderText: "Password for " + entry.ssid
                                echoMode: TextInput.Password
                                inputMethodHints: Qt.ImhSensitiveData
                                onAccepted: root.submitPassword(entry.ssid, text)
                                Keys.onEscapePressed: event => {
                                    root.closePassword();
                                    event.accepted = true;
                                }
                                Component.onCompleted: forceActiveFocus()
                            }

                            TextActionButton {
                                objectName: "wifi-password-cancel"
                                text: "Cancel"
                                onClicked: root.closePassword()
                            }

                            TextActionButton {
                                objectName: "wifi-password-connect"
                                text: "Connect"
                                enabled: passwordField.text.length > 0
                                onClicked: root.submitPassword(entry.ssid, passwordField.text)
                            }
                        }
                    }
                }
            }

            UiText {
                objectName: "wifi-empty-state"
                anchors.centerIn: parent
                visible: networkList.count === 0
                text: !root.radioEnabled ? "Wi-Fi is off" : root.scanning ? "Scanning…" : "No networks found"
                color: Theme.textSecondary
                font.pixelSize: 13
            }
        }
    }
}
