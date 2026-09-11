pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color background: Qt.rgba(26 / 255, 21 / 255, 21 / 255, 0.8)
    readonly property color backgroundAlt: "#241D1D"
    readonly property color backgroundAlpha: Qt.rgba(26 / 255, 21 / 255, 21 / 255, 0.87)
    readonly property color backgroundGray: "#362A2A"
    readonly property color foreground: "#ffe9c7"
    readonly property color foregroundInactive: "#A89184"
    readonly property color primary: "#AE3F82"
    readonly property color muted: "#A89184"
    readonly property color border: "#7B3D79"
    readonly property color secondary: "#756D94"
    readonly property color success: "#959A6B"
    readonly property color warning: "#E39C45"
    readonly property color danger: "#F07342"
}
