pragma Singleton

import QtQuick
import "../../../styles"

QtObject {
    readonly property color background: Theme.background
    readonly property color foreground: Theme.textPrimary
    readonly property color dim: Theme.textSecondary
    readonly property color accent: Theme.accent
    readonly property color accentText: {
        const luminance = accent.r * 0.299 + accent.g * 0.587 + accent.b * 0.114;
        return luminance > 0.5 ? "#101010" : "#ffffff";
    }
    readonly property color urgent: Theme.danger
    readonly property var shellValues: ({})
    readonly property QtObject popups: QtObject {
        readonly property color background: Theme.surface
        readonly property color border: Theme.border
        readonly property color text: Theme.textPrimary
    }
    readonly property QtObject tooltip: QtObject {
        readonly property color background: Theme.surfaceVariant
        readonly property color border: Theme.border
        readonly property color text: Theme.textPrimary
    }
}
