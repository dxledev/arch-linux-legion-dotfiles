pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color background: "#020202"
    readonly property color backgroundAlt: "#0b0b0b"
    readonly property color backgroundAlpha: Qt.rgba(2 / 255, 2 / 255, 2 / 255, 0.92)
    readonly property color backgroundGray: "#1b1919"
    readonly property color foreground: "#d1cfcf"
    readonly property color foregroundInactive: "#8a8888"
    readonly property color primary: "#afa6a6"
    readonly property color muted: "#8a8888"
    readonly property color border: "#d1cfcf"
    readonly property color secondary: "#aea5a5"
    readonly property color success: "#a19797"
    readonly property color warning: "#a89e9e"
    readonly property color danger: "#9a8e8e"
}
