import QtQuick
import "../components"
import "../services"

SettingsPanel {
    title: "Wallpaper animation"
    SettingSection {
        title: "Wallpaper animation"
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
