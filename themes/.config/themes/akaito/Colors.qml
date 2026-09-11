pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color background: "#f3e4cb"
    readonly property color backgroundAlt: "#ead9bc"
    readonly property color backgroundAlpha: Qt.rgba(243 / 255, 228 / 255, 203 / 255, 0.92)
    readonly property color backgroundGray: "#d6c2a1"
    readonly property color foreground: "#4d2e1a"
    readonly property color foregroundInactive: "#755833"
    readonly property color primary: "#a32f1a"
    readonly property color muted: "#9f8253"
    readonly property color border: "#9f8253"
    readonly property color secondary: "#755833"
    readonly property color success: "#a46d2d"
    readonly property color warning: "#a8611f"
    readonly property color danger: "#a4373c"
}
