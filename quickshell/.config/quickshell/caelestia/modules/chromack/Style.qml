pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Caelestia.Config
import qs.services as Services

Singleton {
    readonly property string bodyFontFamily: Tokens.font.body.medium.family
    readonly property int bodyFontWeight: Tokens.font.body.medium.weight
    readonly property var bodyFontAxes: Tokens.font.body.medium.variableAxes
    readonly property string iconFontFamily: "Symbols Nerd Font Mono"
    readonly property color panel: Services.Colours.palette.m3surfaceContainerLow
    readonly property color header: Services.Colours.palette.m3surfaceContainerHigh
    readonly property color content: Services.Colours.palette.m3surfaceContainer
    readonly property color input: Services.Colours.palette.m3surfaceContainerHighest
    readonly property color text: Services.Colours.palette.m3onSurface
    readonly property color muted: Services.Colours.palette.m3onSurfaceVariant
    readonly property color border: Services.Colours.palette.m3outlineVariant
    readonly property color primary: Services.Colours.palette.m3primary
    readonly property color onPrimary: Services.Colours.palette.m3onPrimary
    readonly property color primaryContainer: Services.Colours.palette.m3primaryContainer
    readonly property color onPrimaryContainer: Services.Colours.palette.m3onPrimaryContainer
    readonly property color danger: Services.Colours.palette.m3error
    readonly property color onDanger: Services.Colours.palette.m3onError
    readonly property color dangerContainer: Services.Colours.palette.m3errorContainer
    readonly property color onDangerContainer: Services.Colours.palette.m3onErrorContainer
    readonly property color sliderTrack: Services.Colours.palette.m3secondaryContainer
    readonly property color sliderHandle: Services.Colours.palette.m3surface

    readonly property int padding: 14
    readonly property int gap: 10
    readonly property int inputHeight: 34
    readonly property real inputFontSize: ChromackState.options.inputFontSize ?? 13
    readonly property int inputRadius: 8
    readonly property int contentRadius: 12
    readonly property int panelRadius: 14
    readonly property int headerRadius: 12
    readonly property int buttonRadius: 10
    readonly property int controlBorderWidth: 1
    readonly property int tabOverlap: 1
    readonly property int labelFontSize: 16
    readonly property int titleFontSize: 17
    readonly property int subtitleFontSize: 12
    readonly property int sectionTitleFontSize: 13
    readonly property int captionFontSize: 12
    readonly property real glyphFontSize: 10.67
    readonly property int swatchSize: 24
    readonly property int swatchRadius: 3
    readonly property int pickerHeight: 220
    readonly property int hueWidth: 22
    readonly property int previewWidth: 74
    readonly property int previewHeight: 34
    readonly property int previewRadius: 10
}
