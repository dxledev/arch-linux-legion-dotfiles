import QtQuick
import QtQuick.Controls
import "../../components"
import "../../styles"

AbstractButton {
    id: root
    property color swatchColor: "transparent"
    property string value: ""
    property string description: value
    property bool selected: false
    property real rounding: 4
    property bool outlined: true
    implicitWidth: 22
    implicitHeight: implicitWidth
    hoverEnabled: true
    focusPolicy: Qt.NoFocus
    Accessible.name: description

    HoverHandler {
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    background: Rectangle {
        color: root.swatchColor
        radius: root.rounding
        border.width: root.selected || root.hovered ? 2 : root.outlined ? 1 : 0
        border.color: root.selected || root.hovered ? Theme.textPrimary : Theme.border
        opacity: root.enabled ? 1 : 0.3
    }

    IslandTooltip {
        parent: root
        visible: root.hovered && root.description.length > 0
        text: root.description
    }
}
