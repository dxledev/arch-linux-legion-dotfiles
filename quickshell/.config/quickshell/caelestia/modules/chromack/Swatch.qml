import QtQuick
import QtQuick.Controls as QQC

QQC.AbstractButton {
    id: root
    property color swatchColor: "transparent"
    property string value: ""
    property string tooltip: value
    property bool selected: false
    property real rounding: Style.size("swatch-radius", 3)
    implicitWidth: Style.size("swatch-size", 24)
    implicitHeight: implicitWidth
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    background: Rectangle {
        color: root.swatchColor
        radius: root.rounding
        border.width: root.selected || root.hovered ? 2 : 1
        border.color: root.selected || root.hovered ? Style.text : Style.border
        opacity: root.enabled ? 1 : 0.3
    }
    QQC.ToolTip.visible: hovered && tooltip.length > 0
    QQC.ToolTip.text: tooltip
    QQC.ToolTip.delay: 400
}
