import QtQuick
import QtQuick.Controls
import "../services"
import "../styles"

Column {
    id: root
    required property string label
    required property string setting
    property string suffix: " px"
    property real minimum: 0
    property real maximum: 100
    property real step: 1
    property bool dirty: false
    function saveValue() {
        if (!dirty) return;
        dirty = false;
        ThemeService.setSetting(setting, slider.value);
    }
    width: parent.width
    spacing: 2
    opacity: enabled ? 1 : 0.45
    Row {
        width: parent.width
        UiText { width: parent.width - 85; text: root.label; color: Theme.textPrimary; font.pixelSize: 14 }
        UiText {
            width: 85
            text: (Math.round(slider.value * 100) / 100) + root.suffix
            color: Theme.textSecondary
            font.pixelSize: 13
            horizontalAlignment: Text.AlignRight
        }
    }
    Slider {
        id: slider
        objectName: "setting-slider-" + root.setting
        width: root.width
        height: 30
        from: root.minimum
        to: root.maximum
        stepSize: root.step
        value: ThemeService.settings[root.setting] ?? root.minimum
        enabled: !ThemeService.busy
        onMoved: { root.dirty = true; saveDelay.restart(); }
        onPressedChanged: {
            if (!pressed) { saveDelay.stop(); root.saveValue(); }
        }
        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: 6
            radius: 3
            color: Theme.surfaceVariant
            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: 3
                color: Theme.accent
            }
        }
        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.pressed ? 25 : 22
            height: width
            radius: width / 2
            color: Theme.textPrimary
            border.width: 1
            border.color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.15)
            Behavior on width { NumberAnimation { duration: 120 } }
        }
    }
    Timer {
        id: saveDelay
        interval: 180
        onTriggered: if (!slider.pressed) root.saveValue()
    }
}
