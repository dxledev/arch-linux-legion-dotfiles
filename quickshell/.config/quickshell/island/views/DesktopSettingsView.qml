import QtQuick
import Quickshell
import "../components"
import "../core"
import "../services"
import "../styles"

SettingsPanel {
    title: "Desktop"
    SettingSection {
        title: "Screen"
        objectName: "desktop-screen-section"
        iconSource: "../assets/icons/laptop.svg"
        SettingToggle { objectName: "desktop-screen-corners-toggle"; text: "Screen corners"; setting: "screenCorners" }
        UiText {
            width: parent.width
            text: "Rounds the screen corners in the Island's background color."
            color: Theme.textSecondary
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }
        SettingSlider {
            visible: ThemeService.settings.screenCorners ?? false
            label: "Screen corner radius"
            setting: "screenCornerRadius"
            minimum: 4
            maximum: 64
        }
        UiText {
            visible: ThemeService.settings.screenCorners ?? false
            width: parent.width
            text: "Windows use the same radius."
            color: Theme.textSecondary
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }
    }
}
