import QtQuick
import QtQuick.Controls as QQC

QQC.Button {
    id: root
    property bool glyph: false
    property real glyphSize: Style.glyphFontSize
    property bool danger: false
    property bool tabButton: false
    property bool tabSelected: false
    property string tooltip: ""
    readonly property color labelColor: {
        if (root.tabButton)
            return root.tabSelected ? Style.text : root.hovered ? Style.onPrimaryContainer : Style.muted;
        if (root.danger) {
            if (root.down)
                return Style.onDangerContainer;
            if (root.hovered)
                return Style.onDanger;
        } else {
            if (root.down)
                return Style.onPrimaryContainer;
            if (root.hovered)
                return Style.onPrimary;
        }
        return Style.text;
    }
    readonly property color fillColor: {
        if (root.tabButton)
            return root.tabSelected ? Style.content : root.hovered ? Style.primaryContainer : "transparent";
        if (root.down)
            return root.danger ? Style.dangerContainer : Style.primaryContainer;
        if (root.hovered)
            return root.danger ? Style.danger : Style.primary;
        return "transparent";
    }
    readonly property color outlineColor: root.tabButton ? "transparent" : root.hovered ? (root.danger ? Style.danger : Style.primary) : Style.border
    implicitHeight: Style.inputHeight
    implicitWidth: Math.max(Style.inputHeight, label.implicitWidth + (glyph ? 0 : 24))
    hoverEnabled: true
    contentItem: Label {
        id: label
        text: root.text
        color: root.labelColor
        font.family: root.glyph ? Style.iconFontFamily : Style.bodyFontFamily
        font.weight: Style.bodyFontWeight
        font.variableAxes: Style.bodyFontAxes
        font.pixelSize: root.glyph ? root.glyphSize : Style.labelFontSize
        horizontalAlignment: Text.AlignHCenter
    }
    background: Rectangle {
        color: root.fillColor
        radius: root.tabButton ? 0 : Style.buttonRadius
        topLeftRadius: root.tabButton ? Style.inputRadius : Style.buttonRadius
        topRightRadius: root.tabButton ? Style.inputRadius : Style.buttonRadius
        border.width: root.tabButton ? 0 : Style.controlBorderWidth
        border.color: root.outlineColor
    }
    QQC.ToolTip.visible: hovered && tooltip.length > 0
    QQC.ToolTip.text: tooltip
    QQC.ToolTip.delay: 600
}
