pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

CustomMouseArea {
    id: root

    required property Brightness.Monitor monitor
    required property string label
    property alias showInitialValue: slider.showInitialValue

    implicitWidth: Tokens.sizes.osd.sliderWidth
    implicitHeight: Tokens.sizes.osd.sliderHeight
    enabled: monitor?.initialized ?? false
    hoverEnabled: true

    function onWheel(event: WheelEvent): void {
        if (event.angleDelta.y !== 0)
            monitor.setBrightness(monitor.brightness + Math.sign(event.angleDelta.y) * GlobalConfig.services.brightnessIncrement);
    }

    FilledSlider {
        id: slider

        anchors.fill: parent
        icon: "brightness_" + (Math.round(value * 6) + 1)
        value: root.monitor?.brightness ?? 0
        onMoved: root.monitor.setBrightness(value)
        Accessible.name: root.label + " brightness"
    }

    SliderTooltip {
        parent: root
        Tokens.screen: root.Tokens.screen
        visible: root.containsMouse || slider.hovered || slider.pressed
        text: root.label
    }
}
