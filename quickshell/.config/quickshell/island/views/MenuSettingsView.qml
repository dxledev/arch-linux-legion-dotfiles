import QtQuick
import "../components"

SettingsPanel {
    title: "Menu"
    SettingSection {
        title: "Cards in view"
        iconSource: "../assets/icons/grid.svg"
        SettingSlider { label: "Rows"; setting: "menuRows"; minimum: 2; maximum: 4; suffix: "" }
        SettingSlider { label: "Columns"; setting: "menuColumns"; minimum: 2; maximum: 4; suffix: "" }
    }
}
