import QtQuick
import "../components"
import "../services"
import "../core"

SettingsPanel {
    title: "Workspaces"
    SettingSection {
        title: "Workspaces"
        iconSource: "../assets/icons/workspaces.svg"
        SettingChoice {
            label: "Switcher style"
            choices: ["default", "dots"]
            selected: ThemeService.settings.workspaceStyle || "default"
            onChosen: value => ThemeService.setSetting("workspaceStyle", value)
        }
        SettingSlider {
            label: "Dot size"; setting: "workspaceDotSize"
            minimum: 1; maximum: IslandGeometry.compactHeight - 2
            enabled: ThemeService.settings.workspaceStyle === "dots"
        }
        SettingToggle { text: "Persistent workspaces"; setting: "workspacePersistent" }
        SettingToggle { text: "Show all monitors"; setting: "workspaceShowAllMonitors" }
        SettingSlider {
            label: "Workspace count"; setting: "workspaceCount"
            minimum: 1; maximum: 20; suffix: ""
            enabled: ThemeService.settings.workspacePersistent ?? true
        }
        SettingSlider {
            label: "Animation duration"; setting: "workspaceAnimationDuration"
            maximum: 500; step: 10; suffix: " ms"
        }
    }
}
