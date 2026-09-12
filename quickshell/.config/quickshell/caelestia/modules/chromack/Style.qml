pragma Singleton
import QtQuick
import Quickshell

Singleton {
    function value(key: string, fallback: string): string {
        return ChromackState.data.style[key] || fallback;
    }
    function size(key: string, fallback: real): real {
        return parseFloat(value(key, String(fallback))) || fallback;
    }
    readonly property string font: value("font-family", "Liberation Sans")
    readonly property color text: value("text-color", "#e0def4")
    readonly property color muted: value("text-muted-color", "#908caa")
    readonly property color panel: value("panel-bg", "#191724")
    readonly property color content: value("content-bg", "#1f1d2e")
    readonly property color input: value("input-bg", "#191724")
    readonly property color border: value("border-color", "#403d52")
    readonly property color primary: value("color-primary", "#c4a7e7")
    readonly property color danger: value("color-danger", "#eb6f92")
    readonly property int padding: size("panel-padding", 14)
    readonly property int gap: size("section-gap", 10)
    readonly property int inputHeight: size("input-height", 34)
    readonly property real inputFontSize: ChromackState.options.inputFontSize ?? size("input-font-size", 13)
    readonly property int inputRadius: size("input-radius", 8)
    readonly property int contentRadius: size("content-radius", 12)
}
