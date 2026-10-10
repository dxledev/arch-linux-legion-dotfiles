pragma ComponentBehavior: Bound
import QtQuick
import "../components"
import "../core"
import "../services/MenuEntries.js" as MenuEntries

SettingsPanel {
    id: root
    title: "Settings"
    contentSpacing: 8
    scrollObjectName: "settings-scroll"
    backAction: () => IslandController.openNavigation()
    escapeAction: () => IslandController.reset()
    readonly property var sections: MenuEntries.settingsSections
    Repeater {
        model: root.sections
        SettingLink {
            required property var modelData
            objectName: "settings-entry-" + modelData.key
            textLabel: modelData.title
            iconSource: modelData.icon
            onClicked: IslandController.openSettingsSection(modelData.key)
        }
    }
}
