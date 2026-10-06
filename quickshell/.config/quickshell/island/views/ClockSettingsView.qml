import QtQuick
import "../components"
import "../services"

SettingsPanel {
    title: "Clock"
    SettingSection {
        title: "Format"
        iconSource: "../assets/icons/clock.svg"
        SettingToggle { objectName: "clock-format-toggle"; text: "12-hour time (AM/PM)"; setting: "clock12Hour" }
    }
    SettingSection {
        title: "Text"
        iconSource: "../assets/icons/clock.svg"
        SettingToggle { objectName: "clock-inherit-ui-font"; text: "Inherit UI font"; setting: "clockInheritUiFont" }
        SettingFont { setting: "clockFontFamily"; enabled: !ThemeService.settings.clockInheritUiFont }
        SettingSlider { label: "Font size"; setting: "clockFontSize"; minimum: 8; maximum: 40 }
        SettingToggle { text: "Bold"; setting: "clockFontBold" }
    }
    SettingSection {
        title: "Preview"
        iconSource: "../assets/icons/clock.svg"
        Item {
            width: parent.width
            height: preview.implicitHeight + 24
            ClockView { id: preview; interactive: false; anchors.centerIn: parent }
        }
    }
}
