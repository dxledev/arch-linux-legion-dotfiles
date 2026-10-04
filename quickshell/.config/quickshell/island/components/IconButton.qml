import QtQuick
import QtQuick.Controls
import "../styles"

Button {
    id: root
    property url iconSource
    property string description: ""
    property color iconColor: Theme.textPrimary
    implicitWidth: 36
    implicitHeight: 36
    padding: 9
    Accessible.name: description
    hoverEnabled: true
    contentItem: SvgIcon { source: root.iconSource; color: root.iconColor; size: 18 }
    background: Rectangle {
        radius: height / 2
        color: root.down ? Theme.buttonPressed : root.hovered ? Theme.surfaceVariant : Theme.surface
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.accent
        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
    }
    IslandTooltip {
        parent: root
        visible: root.hovered && root.description.length > 0
        text: root.description
    }
}
