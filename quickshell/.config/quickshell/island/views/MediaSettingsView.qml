import QtQuick
import "../components"

SettingsPanel {
    title: "Media"
    SettingSection {
        title: "Lyrics on the Island"
        iconSource: "../assets/icons/music.svg"
        SettingSlider { objectName: "lyrics-island-min-width"; label: "Minimum width"; setting: "lyricsIslandMinWidth"; minimum: 200; maximum: 800; step: 10 }
    }
}
