pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color background: "#121212"
    readonly property color backgroundAlt: "#121212"
    readonly property color backgroundAlpha: Qt.rgba(51 / 255, 51 / 255, 51 / 255, 0.87)
    readonly property color backgroundGray: "#262626"
    readonly property color foreground: "#bebebe"
    readonly property color foregroundInactive: "#ffffff"
    readonly property color primary: "#8a8a8d"
    readonly property color muted: "#3a3a3a"
    readonly property color border: "#8a8a8d"
    readonly property color secondary: "#bebebe"
    readonly property color success: "#ffc107"
    readonly property color warning: "#b91c1c"
    readonly property color danger: "#d35f5f"
}
