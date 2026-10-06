import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"

PanelWindow {
    WlrLayershell.namespace: "island-reservation"
    WlrLayershell.layer: WlrLayer.Overlay
    anchors.top: true
    implicitWidth: 1
    implicitHeight: 1
    exclusiveZone: IslandGeometry.reservedHeight
    color: "transparent"
    focusable: false
    mask: Region {}
}
