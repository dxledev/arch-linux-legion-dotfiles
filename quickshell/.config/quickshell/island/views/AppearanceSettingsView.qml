import QtQuick
import Quickshell
import "../components"
import "../core"
import "../services"
import "../styles"

SettingsPanel {
    title: "Appearance"
    SettingSection {
        title: "UI"
        objectName: "appearance-ui-section"
        iconSource: "../assets/icons/display.svg"
        SettingFont { label: "Font"; setting: "uiFontFamily"; defaultFont: "Noto Sans" }
        SettingToggle { objectName: "appearance-bold-toggle"; text: "Bold text"; setting: "uiFontBold" }
        SettingSlider { label: "Letter spacing"; setting: "uiLetterSpacing"; maximum: 3; step: 0.25 }
        SettingSlider { label: "Animation duration"; setting: "uiAnimationDuration"; maximum: 1000; step: 10; suffix: " ms" }
    }
    SettingSection {
        title: "Island"
        objectName: "appearance-island-section"
        iconSource: "../assets/icons/clock.svg"
        SettingChoice {
            label: "Monitor"
            choices: ["All", ...Quickshell.screens.map(screen => screen.name)]
            selected: !ThemeService.settings.monitor || ["all", "automatic"].includes(ThemeService.settings.monitor)
                ? "All" : ThemeService.settings.monitor
            onChosen: value => ThemeService.setSetting("monitor", value === "All" ? "all" : value)
        }
        SettingSlider {
            label: "Width"
            setting: "islandWidth"
            minimum: IslandGeometry.minimumWidth(clockMeasure.implicitWidth)
            maximum: 600
        }
        UiText {
            width: parent.width
            text: "Width keeps at least 2 px on each side of the clock."
            color: Theme.textSecondary
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }
        SettingSlider { label: "Height"; setting: "islandHeight"; minimum: Math.max(24, IslandGeometry.minimumHeight); maximum: 80 }
        SettingSlider { label: "Top margin"; setting: "topMargin"; maximum: 80 }
        SettingSlider { label: "Bottom margin"; setting: "reservedSpaceBelow"; maximum: 100 }
        UiText {
            width: parent.width
            text: "Height grows to fit the clock. The top margin, clock height, and bottom margin are reserved for tiled windows."
            color: Theme.textSecondary
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }
        SettingSlider { label: "Corner radius"; setting: "radius"; maximum: 48 }
        SettingSlider { label: "Border width"; setting: "islandBorderWidth"; maximum: 4 }
        SettingSlider { label: "Opacity"; setting: "opacity"; minimum: 0.2; maximum: 1; step: 0.05; suffix: "" }
        SettingSlider { label: "Expansion duration"; setting: "islandAnimationDuration"; maximum: 1000; step: 10; suffix: " ms" }
        SettingToggle { objectName: "island-hover-expand-toggle"; text: "Hover to expand"; setting: "hoverToExpand" }
    }
    ClockView { id: clockMeasure; interactive: false; visible: false }
}
