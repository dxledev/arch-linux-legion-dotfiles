import QtQuick
import "../components"
import "../services"
import "../styles"

SettingsPanel {
    title: "Dynamic palette"
    UiText {
        width: parent.width
        visible: ThemeService.state.source !== "dynamic"
        text: "Choose a dynamic theme to adjust its color mode and palette."
        color: Theme.textSecondary
        font.pixelSize: 12
        wrapMode: Text.Wrap
    }
    SettingSection {
        title: "Dynamic palette"
        iconSource: "../assets/icons/palette.svg"
        enabled: ThemeService.state.source === "dynamic"
        SettingChoice {
            label: "Color mode"; choices: ["dark", "light"]; selected: ThemeService.state.mode
            choiceLabel: value => value.charAt(0).toUpperCase() + value.slice(1)
            onChosen: value => ThemeService.execute(["mode", value])
        }
        SettingChoice {
            label: "Palette"
            choices: ["tonalspot", "vibrant", "expressive", "fidelity", "fruitsalad", "monochrome", "neutral", "rainbow", "content"]
            selected: ThemeService.state.variant
            choiceLabel: value => value.charAt(0).toUpperCase() + value.slice(1)
            onChosen: value => ThemeService.execute(["variant", value])
        }
    }
}
