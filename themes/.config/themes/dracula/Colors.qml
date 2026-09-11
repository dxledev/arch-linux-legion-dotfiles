pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color background: "#282a36"
    readonly property color backgroundAlt: "#282a36"
    readonly property color backgroundAlpha: Qt.rgba(33 / 255, 34 / 255, 44 / 255, 0.87)
    readonly property color backgroundGray: "#3f4254"
    readonly property color foreground: "#f8f8f2"
    readonly property color foregroundInactive: "#ffffff"
    readonly property color primary: "#bd93f9"
    readonly property color muted: "#44475a"
    readonly property color border: "#8be9fd"
    readonly property color secondary: "#8be9fd"
    readonly property color success: "#50fa7b"
    readonly property color warning: "#f1fa8c"
    readonly property color danger: "#ff5555"
}
