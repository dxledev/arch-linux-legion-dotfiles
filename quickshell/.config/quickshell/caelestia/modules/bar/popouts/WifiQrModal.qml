pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import "WifiQrModel.js" as WifiQrModel

Item {
    id: root

    required property ShellScreen screen

    property bool opened: false
    property string iface: ""
    property string ssid: ""
    property bool secured: false
    property var qrRows: []
    property int qrSize: 0
    property string error: ""
    property bool loading: false
    property bool expectedStop: false
    property bool pendingShow: false
    property string pendingIface: ""
    property string password: ""
    property bool passwordHovered: false
    property string passwordError: ""
    property bool passwordExpectedStop: false

    readonly property bool showingQr: qrSize > 0 && !loading && error === ""
    readonly property color onScrim: "white"
    readonly property color onScrimDim: Qt.rgba(1, 1, 1, 0.55)
    readonly property color onScrimUrgent: "#ff6b6b"
    readonly property string qrScript: Quickshell.shellPath("integration/wifi-qr")
    readonly property string passwordScript: Quickshell.shellPath("integration/wifi-password")

    function open(requestedSsid: string, requestedIface: string): void {
        root.ssid = requestedSsid;
        generate(requestedIface);
        root.opened = true;
        Qt.callLater(() => {
            if (root.opened)
                keyCatcher.forceActiveFocus();
        });
    }

    function close(): void {
        root.opened = false;
        root.pendingShow = false;
        if (qrProc.running) {
            root.expectedStop = true;
            qrProc.running = false;
        }
        if (passwordProc.running) {
            root.passwordExpectedStop = true;
            passwordProc.running = false;
        }
        root.qrSize = 0;
        root.qrRows = [];
        root.error = "";
        root.loading = false;
        root.iface = "";
        root.ssid = "";
        root.secured = false;
        root.password = "";
        root.passwordHovered = false;
        root.passwordError = "";
    }

    function generate(requestedIface: string): void {
        if (qrProc.running) {
            root.pendingShow = true;
            root.pendingIface = requestedIface;
            if (!root.expectedStop) {
                root.expectedStop = true;
                qrProc.running = false;
            }
            return;
        }

        root.qrSize = 0;
        root.qrRows = [];
        root.error = "";
        root.loading = true;
        root.expectedStop = false;
        root.iface = "";
        root.secured = false;
        root.password = "";
        root.passwordHovered = false;
        root.passwordError = "";
        if (passwordProc.running) {
            root.passwordExpectedStop = true;
            passwordProc.running = false;
        }
        qrProc.command = requestedIface ? ["/usr/bin/bash", root.qrScript, "--meta", requestedIface] : ["/usr/bin/bash", root.qrScript, "--meta"];
        qrProc.running = true;
    }

    function updateQr(raw: string): void {
        const parsed = WifiQrModel.parseQrOutput(raw);
        root.qrRows = parsed.matrix.rows;
        root.qrSize = parsed.matrix.size;
        if (parsed.meta.ssid !== "")
            root.ssid = parsed.meta.ssid;
        if (parsed.meta.iface !== "")
            root.iface = parsed.meta.iface;
        root.secured = parsed.meta.security !== "" && parsed.meta.security !== "nopass";
        if (root.qrSize > 0)
            root.error = "";
    }

    function revealPassword(): void {
        if (root.password !== "")
            return;
        if (passwordProc.running || !root.iface)
            return;

        root.passwordError = "";
        root.passwordExpectedStop = false;
        passwordProc.command = ["/usr/bin/bash", root.passwordScript, root.iface];
        passwordProc.running = true;
    }

    Process {
        id: qrProc

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (!root.expectedStop)
                    root.updateQr(text);
            }
        }

        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (!root.expectedStop)
                    root.error = String(text || "").trim();
            }
        }

        onExited: exitCode => {
            root.loading = false;
            if (root.pendingShow) {
                root.pendingShow = false;
                Qt.callLater(() => root.generate(root.pendingIface));
                return;
            }
            if (root.expectedStop)
                return;
            if (exitCode !== 0 || root.qrSize === 0) {
                root.qrSize = 0;
                root.qrRows = [];
                if (root.error === "")
                    root.error = "Could not generate the Wi-Fi QR code";
            }
        }
    }

    Process {
        id: passwordProc

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (root.opened && !root.passwordExpectedStop)
                    root.password = String(text || "").trim();
            }
        }

        onExited: exitCode => {
            if (root.passwordExpectedStop || !root.opened)
                return;
            if (exitCode !== 0 || root.password === "")
                root.passwordError = "Could not read the Wi-Fi password";
        }
    }

    PanelWindow {
        visible: root.opened
        screen: root.screen
        color: "transparent"

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        WlrLayershell.namespace: "caelestia-wifi-qr"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.78)

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Item {
            id: keyCatcher

            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.close()

            Item {
                anchors.centerIn: parent
                width: content.implicitWidth
                height: content.implicitHeight
                scale: Math.min(1, (keyCatcher.width - Tokens.padding.extraExtraLarge * 2) / Math.max(1, width), (keyCatcher.height - Tokens.padding.extraExtraLarge * 2) / Math.max(1, height))

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                ColumnLayout {
                    id: content

                    anchors.fill: parent
                    spacing: Tokens.spacing.large

                    StyledText {
                        Layout.maximumWidth: 320
                        Layout.alignment: Qt.AlignHCenter
                        text: (root.ssid || "Wi-Fi").toUpperCase()
                        color: root.onScrimDim
                        font.weight: Font.Bold
                        font.letterSpacing: 2
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        id: qrCanvas

                        readonly property int moduleSize: root.qrSize > 0 ? Math.max(4, Math.floor(240 / root.qrSize)) : 0

                        visible: root.showingQr
                        width: root.qrSize * moduleSize
                        height: width
                        color: "white"
                        radius: Tokens.rounding.large
                        Layout.alignment: Qt.AlignHCenter

                        Grid {
                            anchors.fill: parent
                            columns: root.qrSize

                            Repeater {
                                model: root.qrSize * root.qrSize

                                Rectangle {
                                    required property int index

                                    readonly property int matrixRow: Math.floor(index / root.qrSize)
                                    readonly property int matrixColumn: index % root.qrSize

                                    width: qrCanvas.moduleSize
                                    height: qrCanvas.moduleSize
                                    color: root.qrRows[matrixRow].charAt(matrixColumn) === "1" ? "#111111" : "transparent"
                                }
                            }
                        }
                    }

                    StyledText {
                        visible: root.loading
                        Layout.fillWidth: true
                        text: "Generating QR code…"
                        color: root.onScrimDim
                        horizontalAlignment: Text.AlignHCenter
                    }

                    StyledText {
                        visible: root.error !== ""
                        Layout.fillWidth: true
                        Layout.maximumWidth: 320
                        text: root.error
                        color: root.onScrimUrgent
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }

                    StyledText {
                        visible: root.showingQr
                        Layout.fillWidth: true
                        text: "Scan to join this network"
                        color: root.onScrimDim
                        horizontalAlignment: Text.AlignHCenter
                    }

                    StyledText {
                        visible: root.showingQr && root.secured
                        Layout.fillWidth: true
                        Layout.maximumWidth: 320
                        text: root.passwordError !== "" ? root.passwordError : root.passwordHovered && root.password !== "" ? root.password : "••••••••"
                        color: root.passwordError !== "" ? root.onScrimUrgent : root.onScrim
                        opacity: root.passwordHovered || root.passwordError !== "" ? 1 : 0.6
                        wrapMode: Text.WrapAnywhere
                        horizontalAlignment: Text.AlignHCenter

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                root.passwordHovered = true;
                                root.revealPassword();
                            }
                            onExited: root.passwordHovered = false
                        }
                    }
                }
            }
        }
    }
}
