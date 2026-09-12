import QtQuick
import Caelestia.Config
import qs.components.controls
import qs.services

IconButton {
    id: root

    implicitWidth: Tokens.sizes.osd.sliderWidth
    implicitHeight: implicitWidth
    icon: Nightlight.enabled ? "nightlight" : "light_mode"
    isToggle: true
    isRound: true
    checked: Nightlight.enabled
    onClicked: Nightlight.toggle()
    Accessible.name: "Nightlight"

    OsdTooltip {
        parent: root
        Tokens.screen: root.Tokens.screen
        visible: root.hovered || root.pressed
        text: Nightlight.enabled ? "Nightlight on" : "Nightlight off"
    }
}
