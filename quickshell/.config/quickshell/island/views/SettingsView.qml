pragma ComponentBehavior: Bound
import QtQuick
import "../components"
import "../core"

SettingsPanel {
    id: root
    title: "Settings"
    contentSpacing: 8
    scrollObjectName: "settings-scroll"
    backAction: () => IslandController.openNavigation()
    escapeAction: () => IslandController.reset()
    readonly property var sections: [
        {key: "appearance", title: "Appearance", icon: "../assets/icons/display.svg"},
        {key: "clock", title: "Clock", icon: "../assets/icons/clock.svg"},
        {key: "osd", title: "OSD", icon: "../assets/icons/osd.svg"},
        {key: "workspaces", title: "Workspaces", icon: "../assets/icons/workspaces.svg"},
        {key: "dynamicPalette", title: "Dynamic palette", icon: "../assets/icons/palette.svg"},
        {key: "notifications", title: "Notifications", icon: "../assets/icons/bell.svg"},
        {key: "interaction", title: "Interaction", icon: "../assets/icons/touch.svg"},
        {key: "wallpaperAnimation", title: "Wallpaper animation", icon: "../assets/icons/sparkles.svg"}
    ]
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
