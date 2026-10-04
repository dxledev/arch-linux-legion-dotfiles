import QtQuick
import "../views"
import "../core"

Item {
    implicitWidth: Math.max(160, clock.implicitWidth + 40)
    implicitHeight: IslandGeometry.compactHeight
    ClockView { id: clock; anchors.centerIn: parent }
}
