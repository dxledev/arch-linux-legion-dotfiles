import QtQuick
import "../components"

SettingsPanel {
    title: "Interaction"
    SettingSection {
        title: "Interaction"
        iconSource: "../assets/icons/touch.svg"
        SettingSlider { label: "Hover delay"; setting: "hoverDelay"; maximum: 1000; step: 25; suffix: " ms" }
        SettingSlider { label: "Collapse delay"; setting: "collapseDelay"; maximum: 1500; step: 25; suffix: " ms" }
        SettingToggle { text: "Audio visualizer"; setting: "visualizer" }
    }
    SettingSection {
        title: "Scrolling"
        iconSource: "../assets/icons/touch.svg"
        SettingSlider { label: "Smoothing duration"; setting: "scrollAnimationDuration"; maximum: 1000; step: 10; suffix: " ms" }
        SettingSlider { label: "Wheel distance"; setting: "scrollWheelStep"; minimum: 16; maximum: 200; step: 8 }
    }
    SettingSection {
        title: "Scroll indicator"
        iconSource: "../assets/icons/touch.svg"
        SettingToggle { text: "Always visible"; setting: "scrollProgressAlwaysVisible" }
        SettingSlider { label: "Visible duration"; setting: "scrollProgressVisibleDuration"; minimum: 100; maximum: 10000; step: 100; suffix: " ms" }
        SettingToggle { text: "Show full indicator on pages without scrolling"; setting: "scrollProgressShowOnNonScrollable" }
        SettingSlider { label: "Animation duration"; setting: "scrollProgressAnimationDuration"; maximum: 1000; step: 10; suffix: " ms" }
    }
}
