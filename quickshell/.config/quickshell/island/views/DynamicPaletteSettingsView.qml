import QtQuick
import "../components"
import "../services"
import "../styles"

SettingsPanel {
    id: root
    title: "Dynamic palette"

    readonly property string generatedPrefix: "generated:"
    readonly property var materialVariants: ["tonalspot", "vibrant", "expressive", "fidelity", "fruitsalad", "monochrome", "neutral", "rainbow", "content"]
    // Palettes stored by Browse Wallpapers for this wallpaper join the list; other wallpapers show Material only.
    readonly property var generatedStyles: ThemeService.generatedStyles()
    readonly property var paletteChoices: [...generatedStyles.map(style => generatedPrefix + style), ...materialVariants]
    readonly property string selectedPalette: ThemeService.generatedPaletteActive
        ? generatedPrefix + ThemeService.activeGeneratedStyle : ThemeService.state.variant

    function paletteLabel(value) {
        if (value.startsWith(generatedPrefix)) {
            const scheme = value.slice(generatedPrefix.length + 3);
            return scheme.split("-").map(part => part.charAt(0).toUpperCase() + part.slice(1)).join(" ") + " · Wallhaven";
        }
        return ({tonalspot: "Tonal Spot", fruitsalad: "Fruit Salad"})[value]
            ?? value.charAt(0).toUpperCase() + value.slice(1);
    }

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
            // A generated palette keeps its own light and dark pair, so a mode change stays inside it.
            onChosen: value => ThemeService.generatedPaletteActive
                ? ThemeService.execute(["aether-select", ThemeService.activeGeneratedStyle, value])
                : ThemeService.execute(["mode", value])
        }
        SettingChoice {
            label: "Palette"
            choices: root.paletteChoices
            selected: root.selectedPalette
            choiceLabel: root.paletteLabel
            onChosen: value => value.startsWith(root.generatedPrefix)
                ? ThemeService.execute(["aether-select", value.slice(root.generatedPrefix.length), ThemeService.state.mode])
                : ThemeService.execute(["variant", value])
        }
        UiText {
            width: parent.width
            visible: root.generatedStyles.length > 0
            text: "Palettes marked Wallhaven were generated for this wallpaper in Browse Wallpapers."
            color: Theme.textMuted
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }
    }
}
