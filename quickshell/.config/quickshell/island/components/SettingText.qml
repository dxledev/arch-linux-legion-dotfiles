import QtQuick
import "../services"
import "../styles"

// A text setting saved when the field is confirmed (Enter) or loses focus.
Column {
    id: root
    required property string label
    required property string setting
    property string placeholder: ""
    readonly property string stored: String(ThemeService.settings[setting] ?? "")
    width: parent.width
    spacing: 8
    opacity: enabled ? 1 : 0.45
    onStoredChanged: if (!field.activeFocus) field.text = stored
    UiText { text: root.label; color: Theme.textPrimary; font.pixelSize: 14 }
    SearchField {
        onNavigateDown: stepDown()
        id: field
        objectName: "setting-text-" + root.setting
        width: root.width
        text: root.stored
        placeholderText: root.placeholder
        enabled: !ThemeService.busy
        onEditingFinished: if (text !== root.stored) ThemeService.setSetting(root.setting, text)
    }
    // A rejected value (a relative path) is not kept in the field.
    Connections {
        target: ThemeService
        function onErrorChanged() { if (ThemeService.error) field.text = root.stored; }
    }
}
