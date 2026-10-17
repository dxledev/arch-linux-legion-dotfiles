import QtQuick
import "../styles"

// The outline a mouse-only control shows while it holds keyboard focus; invisible otherwise, so the resting UI is unchanged.
Rectangle {
    property Item control: parent
    anchors.fill: parent
    radius: control && control.radius !== undefined ? control.radius : height / 2
    color: "transparent"
    border.width: control && control.activeFocus ? 2 : 0
    border.color: Theme.accent
}
