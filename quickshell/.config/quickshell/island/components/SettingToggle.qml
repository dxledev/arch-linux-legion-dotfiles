import QtQuick
import QtQuick.Controls
import "../services"
import "../styles"

Switch {
    id: root
    required property string setting
    width: parent.width
    height: 40
    padding: 0
    checked: ThemeService.settings[setting] ?? false
    enabled: !ThemeService.busy
    onToggled: ThemeService.setSetting(setting, checked)
    contentItem: Text {
        text: root.text
        color: Theme.textPrimary
        font.pixelSize: 14
        verticalAlignment: Text.AlignVCenter
        rightPadding: 64
    }
    indicator: Rectangle {
        x: root.width - width
        y: (root.height - height) / 2
        width: 50
        height: 30
        radius: 15
        color: root.checked ? Theme.accent : Theme.surfaceVariant
        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
        Rectangle {
            x: root.checked ? parent.width - width - 3 : 3
            y: 3
            width: 24
            height: 24
            radius: 12
            color: Theme.textPrimary
            Behavior on x { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
        }
    }
}
