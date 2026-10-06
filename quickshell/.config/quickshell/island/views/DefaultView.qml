import QtQuick
import "../views"
import "../core"
import "../services"

Item {
    implicitWidth: Math.max(ThemeService.settings.islandWidth ?? 160, IslandGeometry.minimumWidth(clock.implicitWidth))
    implicitHeight: IslandGeometry.compactHeight
    ClockView { id: clock; anchors.centerIn: parent; anchors.alignWhenCentered: false }
}
