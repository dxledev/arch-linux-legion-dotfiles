pragma Singleton

import QtQuick
import Caelestia.Config
import qs.services as Services

QtObject {
    readonly property color panel: Services.Colours.palette.m3surfaceContainerLow
    readonly property color row: Services.Colours.palette.m3surfaceContainer
    readonly property color rowHover: Services.Colours.palette.m3surfaceContainerHigh
    readonly property color text: Services.Colours.palette.m3onSurface
    readonly property color muted: Services.Colours.palette.m3onSurfaceVariant
    readonly property color accent: Services.Colours.palette.m3primary
    readonly property color outline: Services.Colours.palette.m3outlineVariant
    readonly property color error: Services.Colours.palette.m3error
    readonly property color onError: Services.Colours.palette.m3onError
    readonly property int padding: Tokens.padding.large
    readonly property int gap: Tokens.spacing.medium
    readonly property int rowHeight: Math.max(56, ClipboardState.options.rowHeight ?? 64)
    readonly property int rowPadding: 10
    readonly property int rowGap: 4
    readonly property int thumbnailSize: 40
}
