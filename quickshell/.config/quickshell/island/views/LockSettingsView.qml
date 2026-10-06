import QtQuick
import "../components"

SettingsPanel {
    title: "Lock screen"
    SettingSection {
        title: "Background"
        iconSource: "../assets/icons/lock.svg"
        SettingSlider { label: "Snapshot blur"; setting: "lockBlurRadius"; minimum: 0; maximum: 128; suffix: " px" }
        SettingSlider { label: "Background dimming"; setting: "lockDimOpacity"; minimum: 0; maximum: 100; suffix: "%" }
    }
    SettingSection {
        title: "Clock"
        iconSource: "../assets/icons/clock.svg"
        SettingFont { setting: "lockFontFamily" }
        SettingSlider { label: "Clock size"; setting: "lockClockSize"; minimum: 72; maximum: 160 }
        SettingToggle { text: "12-hour time (AM/PM)"; setting: "clock12Hour" }
    }
    SettingSection {
        title: "Details"
        iconSource: "../assets/icons/lock.svg"
        SettingToggle { text: "Media controls"; setting: "lockShowMedia" }
        SettingToggle { text: "Battery status"; setting: "lockShowBattery" }
        SettingSlider { label: "Animation duration"; setting: "lockAnimationDuration"; minimum: 0; maximum: 1000; suffix: " ms" }
    }
}
