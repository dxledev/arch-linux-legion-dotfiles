pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color background: "#121212"
    readonly property color backgroundAlt: "#1b1717"
    readonly property color backgroundAlpha: Qt.rgba(18 / 255, 18 / 255, 18 / 255, 0.87)
    readonly property color backgroundGray: "#241919"
    readonly property color foreground: "#ded3d3"
    readonly property color foregroundInactive: "#b89494"
    readonly property color primary: "#ce5757"
    readonly property color muted: "#b89494"
    readonly property color border: "#b89494"
    readonly property color secondary: "#d48484"
    readonly property color success: "#cc7a7a"
    readonly property color warning: "#d48484"
    readonly property color danger: "#e96565"
}
