import QtQuick
import QtQuick.Controls as QQC

QQC.Button {
    id: root
    property bool glyph: false
    property real glyphSize: Style.size("header-icon-font-size", 10.67)
    property bool danger: false
    property string tooltip: ""
    implicitHeight: Style.inputHeight
    implicitWidth: Math.max(Style.inputHeight, label.implicitWidth + (glyph ? 0 : 24))
    hoverEnabled: true
    contentItem: Label {
        id: label
        text: root.text
        color: root.hovered ? (root.danger ? Style.danger : Style.primary) : Style.text
        font.family: root.glyph ? Style.value("header-icon-font-family", "Symbols Nerd Font Mono") : Style.font
        font.pixelSize: root.glyph ? root.glyphSize : Style.size("font-size", 16)
        horizontalAlignment: Text.AlignHCenter
    }
    background: Rectangle {
        color: root.down ? Style.content : "transparent"
        radius: Style.size("button-radius", 10)
        border.width: Style.size("control-border-width", 1)
        border.color: root.hovered ? (root.danger ? Style.danger : Style.primary) : Style.border
    }
    QQC.ToolTip.visible: hovered && tooltip.length > 0
    QQC.ToolTip.text: tooltip
    QQC.ToolTip.delay: 600
}
