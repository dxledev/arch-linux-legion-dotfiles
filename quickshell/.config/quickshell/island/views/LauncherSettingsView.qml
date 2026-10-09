import QtQuick
import "../components"
import "../services"

SettingsPanel {
    title: "App launcher"
    SettingSection {
        title: "Apps"
        iconSource: "../assets/icons/apps.svg"
        SettingToggle { text: "Show all apps"; setting: "launcherShowAllApps" }
        SettingToggle { text: "Colorize app icons"; setting: "launcherColorizeIcons" }
        SettingChoice {
            label: "Default order"
            choices: ["App list order", "Alphabetical", "Most used", "Recently used"]
            selected: ThemeService.settings.launcherDefaultOrder || "App list order"
            onChosen: value => ThemeService.setSetting("launcherDefaultOrder", value)
        }
    }
    SettingSection {
        title: "Search"
        iconSource: "../assets/icons/apps.svg"
        SettingChoice {
            label: "Matching"
            choices: ["Fuzzy", "Contains"]
            selected: ThemeService.settings.launcherMatching || "Fuzzy"
            onChosen: value => ThemeService.setSetting("launcherMatching", value)
        }
        SettingChoice {
            label: "Search result order"
            choices: ["Relevance", "Alphabetical", "App list order", "Most used", "Recently used"]
            selected: ThemeService.settings.launcherSearchOrder || "Relevance"
            onChosen: value => ThemeService.setSetting("launcherSearchOrder", value)
        }
        SettingToggle { text: "Search descriptions and keywords"; setting: "launcherSearchDescriptions" }
    }
}
