pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color background: "#1a1b26"
    readonly property color backgroundAlt: "#1a1b26"
    readonly property color backgroundAlpha: Qt.rgba(50 / 255, 52 / 255, 74 / 255, 0.87)
    readonly property color backgroundGray: "#313448"
    readonly property color foreground: "#c0caf5"
    readonly property color foregroundInactive: "#acb0d0"
    readonly property color primary: "#7dcfff"
    readonly property color muted: "#414868"
    readonly property color border: "#7dcfff"
    readonly property color secondary: "#7dcfff"
    readonly property color success: "#9ece6a"
    readonly property color warning: "#e0af68"
    readonly property color danger: "#f7768e"
}
