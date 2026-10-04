import QtQuick
import Quickshell
import "../components"
import "../services"
import "../styles"

SettingsPanel {
    title: "Appearance"
    SettingSection {
        title: "Appearance"
        iconSource: "../assets/icons/display.svg"
        SettingChoice {
            label: "Monitor"
            choices: ["All", ...Quickshell.screens.map(screen => screen.name)]
            selected: !ThemeService.settings.monitor || ["all", "automatic"].includes(ThemeService.settings.monitor)
                ? "All" : ThemeService.settings.monitor
            onChosen: value => ThemeService.setSetting("monitor", value === "All" ? "all" : value)
        }
        SettingSlider { label: "Top margin"; setting: "topMargin"; maximum: 80 }
        SettingSlider { label: "Space below Island"; setting: "reservedSpaceBelow"; maximum: 100 }
        Text {
            width: parent.width
            text: "The clock and its top margin are always reserved."
            color: Theme.textSecondary
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }
        SettingSlider { label: "Corner radius"; setting: "radius"; maximum: 48 }
        SettingSlider { label: "Opacity"; setting: "opacity"; minimum: 0.2; maximum: 1; step: 0.05; suffix: "" }
    }
}
