pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color background: "#181a1f"
    readonly property color backgroundAlt: "#20232a"
    readonly property color backgroundAlpha: Qt.rgba(24 / 255, 26 / 255, 31 / 255, 0.92)
    readonly property color backgroundGray: "#2b2f37"
    readonly property color foreground: "#eceff2"
    readonly property color foregroundInactive: "#8f949c"
    readonly property color primary: "#ff2222"
    readonly property color muted: "#8f949c"
    readonly property color border: "#2b2f37"
    readonly property color secondary: "#c3c8d0"
    readonly property color success: "#d12b2b"
    readonly property color warning: "#c3c8d0"
    readonly property color danger: "#b31414"
}
