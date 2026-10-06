import QtQuick
import "../components"
import "../services"

SettingsPanel {
    title: "OSD"
    SettingSection {
        title: "Text"
        iconSource: "../assets/icons/osd.svg"
        SettingToggle { objectName: "osd-inherit-ui-font"; text: "Inherit UI font"; setting: "osdInheritUiFont" }
        SettingFont { setting: "osdFontFamily"; enabled: !ThemeService.settings.osdInheritUiFont }
        SettingSlider { label: "Font size"; setting: "osdFontSize"; minimum: 8; maximum: 40 }
        SettingToggle { text: "Bold"; setting: "osdFontBold" }
        SettingSlider { label: "Icon size"; setting: "osdIconSize"; minimum: 8; maximum: 40 }
        SettingToggle { text: "Show percentage"; setting: "osdShowPercentage" }
    }
    SettingSection {
        title: "Slider"
        iconSource: "../assets/icons/settings.svg"
        SettingSlider { label: "Width"; setting: "osdSliderWidth"; minimum: 60; maximum: 500; step: 10 }
        SettingSlider { label: "Thickness"; setting: "osdSliderHeight"; minimum: 2; maximum: 24 }
        SettingSlider { label: "Corner radius"; setting: "osdSliderRadius"; maximum: 12 }
        SettingSlider { label: "Value animation"; setting: "osdSliderAnimationDuration"; maximum: 1000; step: 10; suffix: " ms" }
    }
    SettingSection {
        title: "Timing"
        iconSource: "../assets/icons/osd.svg"
        SettingSlider { label: "Appear / disappear animation"; setting: "osdAnimationDuration"; maximum: 1000; step: 10; suffix: " ms" }
        SettingSlider { label: "Display duration"; setting: "osdTimeout"; minimum: 500; maximum: 10000; step: 100; suffix: " ms" }
    }
    SettingSection {
        title: "Preview"
        iconSource: "../assets/icons/osd.svg"
        OsdSliderRow { width: Math.min(implicitWidth, parent.width); icon: "󰕾"; value: 65 }
    }
}
