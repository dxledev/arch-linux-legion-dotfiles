import QtQuick
import "../components"
import "../services"

SettingsPanel {
    title: "Wallpaper"
    SettingSection {
        title: "Gallery layout"
        iconSource: "../assets/icons/grid.svg"
        SettingSlider { label: "Rows"; setting: "wallpaperRows"; minimum: 1; maximum: 5; suffix: "" }
        SettingSlider { label: "Columns"; setting: "wallpaperColumns"; minimum: 2; maximum: 5; suffix: "" }
        SettingChoice {
            label: "Scroll"; choices: ["vertical", "horizontal"]
            selected: ThemeService.settings.wallpaperScrollDirection || "vertical"
            onChosen: value => ThemeService.setSetting("wallpaperScrollDirection", value)
        }
        // Wrapping only makes sense for a single-row carousel.
        SettingToggle {
            text: "Infinite scroll"; setting: "wallpaperInfiniteScroll"
            enabled: !ThemeService.busy && (ThemeService.settings.wallpaperRows ?? 3) === 1
            opacity: enabled ? 1 : 0.45
        }
    }
    SettingSection {
        title: "Animation"
        iconSource: "../assets/icons/sparkles.svg"
        SettingChoice {
            label: "Transition"; choices: ["none", "simple", "fade", "wipe", "wave", "grow", "center", "outer", "random"]
            selected: ThemeService.settings.transition || "grow"
            onChosen: value => ThemeService.setSetting("transition", value)
        }
        SettingSlider { label: "Duration"; setting: "transitionDuration"; maximum: 10; step: 0.1; suffix: " s" }
        SettingSlider { label: "Frame rate"; setting: "transitionFps"; minimum: 30; maximum: 240; step: 30; suffix: " fps" }
    }
}
