pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color background: Qt.rgba(0 / 255, 43 / 255, 54 / 255, 0.85)
    readonly property color backgroundAlt: Qt.rgba(0 / 255, 43 / 255, 54 / 255, 1)
    readonly property color backgroundAlpha: Qt.rgba(7 / 255, 54 / 255, 66 / 255, 0.87)
    readonly property color backgroundGray: "#1c4f5b"
    readonly property color foreground: "#839496"
    readonly property color foregroundInactive: "#586e75"
    readonly property color primary: "#268bd2"
    readonly property color muted: "#365863"
    readonly property color border: "#268bd2"
    readonly property color secondary: "#2aa198"
    readonly property color success: "#859900"
    readonly property color warning: "#cb4b16"
    readonly property color danger: "#dc322f"
}
