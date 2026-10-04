import QtQuick
import "../components"
import "../core"
import "../services"

FocusScope {
    implicitWidth: 460
    implicitHeight: 420
    Component.onCompleted: forceActiveFocus()
    Keys.onEscapePressed: IslandController.reset()
    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20
        PanelHeader { title: "Menu"; onBack: IslandController.openExpanded() }
        Grid {
            width: parent.width
            columns: 2
            spacing: 12
            NavigationCard {
                width: (parent.width - parent.spacing) / 2
                title: "Themes"; subtitle: "Colors and palettes"; iconSource: "../assets/icons/palette.svg"
                onClicked: IslandController.openThemeSelector()
            }
            NavigationCard {
                width: (parent.width - parent.spacing) / 2
                title: "Wallpapers"; subtitle: "Choose your backdrop"; iconSource: "../assets/icons/wallpaper.svg"
                onClicked: IslandController.openWallpaperSelector()
            }
            NavigationCard {
                width: (parent.width - parent.spacing) / 2
                title: "Settings"; subtitle: "Make Island yours"; iconSource: "../assets/icons/settings.svg"
                onClicked: IslandController.openSettings()
            }
            NavigationCard {
                width: (parent.width - parent.spacing) / 2
                title: "Shell mode"; subtitle: "Switch your workspace"; iconSource: "../assets/icons/shell.svg"
                onClicked: IslandController.openShellSwitcher()
            }
        }
    }
}
