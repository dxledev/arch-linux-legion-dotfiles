pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color background: "#282828"
    readonly property color backgroundAlt: "#282828"
    readonly property color backgroundAlpha: Qt.rgba(60 / 255, 56 / 255, 54 / 255, 0.87)
    readonly property color backgroundGray: "#3a3a3a"
    readonly property color foreground: "#ebdbb2"
    readonly property color foregroundInactive: "#bdae93"
    readonly property color primary: "#689d6a"
    readonly property color muted: "#665c54"
    readonly property color border: "#a89984"
    readonly property color secondary: "#89b482"
    readonly property color success: "#a9b665"
    readonly property color warning: "#fe8019"
    readonly property color danger: "#ea6962"
}
