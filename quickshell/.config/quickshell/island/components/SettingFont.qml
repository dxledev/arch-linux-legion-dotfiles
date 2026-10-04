import QtQuick
import "../services"

SettingChoice {
    required property string setting
    property string defaultFont: "JetBrainsMono Nerd Font"
    label: "Font"
    choices: [...new Set([selected, ...Qt.fontFamilies()])].sort()
    selected: ThemeService.settings[setting] || defaultFont
    onChosen: value => ThemeService.setSetting(setting, value)
}
