pragma Singleton

import QtQuick
import qs.services

QtObject {
    readonly property color background: Colours.palette.m3surface
    readonly property color foreground: Colours.palette.m3onSurface
    readonly property color dim: Colours.palette.m3onSurfaceVariant
    readonly property color accent: Colours.palette.m3primary
    readonly property color accentText: Colours.palette.m3onPrimary
    readonly property color urgent: Colours.palette.m3error
    readonly property var shellValues: ({})
    readonly property QtObject popups: QtObject {
        readonly property color background: Colours.palette.m3surface
        readonly property color border: Colours.palette.m3outlineVariant
        readonly property color text: Colours.palette.m3onSurface
    }
    readonly property QtObject tooltip: QtObject {
        readonly property color background: Colours.palette.m3surfaceContainerHigh
        readonly property color border: Colours.palette.m3outlineVariant
        readonly property color text: Colours.palette.m3onSurface
    }
}
