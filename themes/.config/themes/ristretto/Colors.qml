pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color background: "#2c2525"
    readonly property color backgroundAlt: "#241f1f"
    readonly property color backgroundAlpha: Qt.rgba(44 / 255, 37 / 255, 37 / 255, 0.87)
    readonly property color backgroundGray: "#3a3132"
    readonly property color foreground: "#e6d9db"
    readonly property color foregroundInactive: "#948a8b"
    readonly property color primary: "#fabd2f"
    readonly property color muted: "#724939"
    readonly property color border: "#d57d63"
    readonly property color secondary: "#85dacc"
    readonly property color success: "#adda78"
    readonly property color warning: "#f9cc6c"
    readonly property color danger: "#fd6883"
}
