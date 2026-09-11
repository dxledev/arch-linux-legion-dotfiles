pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color background: Qt.rgba(0 / 255, 23 / 255, 46 / 255, 0.8)
    readonly property color backgroundAlt: "#00172e"
    readonly property color backgroundAlpha: Qt.rgba(0 / 255, 23 / 255, 46 / 255, 0.87)
    readonly property color backgroundGray: "#093244"
    readonly property color foreground: "#f6dcac"
    readonly property color foregroundInactive: "#5d8b90"
    readonly property color primary: "#faa968"
    readonly property color muted: "#134e5a"
    readonly property color border: "#faa968"
    readonly property color secondary: "#8cbfb8"
    readonly property color success: "#028391"
    readonly property color warning: "#e97b3c"
    readonly property color danger: "#f85525"
}
