import QtQuick
import "../views"
import "../core"
import "../components"
import "../services"
import "../styles"

Item {
    id: root

    // Set by the island on the monitor whose clock the lyrics have taken over.
    property bool lyricsActive: false
    // Falls back to the clock while there is nothing to sing (loading, none found, no player).
    readonly property bool showLyrics: lyricsActive && MediaService.hasPlayer && LyricsService.hasLyrics
    readonly property real clockWidth: Math.max(ThemeService.settings.islandWidth ?? 160, IslandGeometry.minimumWidth(clock.implicitWidth))
    readonly property real lyricWidth: 340

    implicitWidth: showLyrics ? Math.max(clockWidth, lyricWidth) : clockWidth
    implicitHeight: IslandGeometry.compactHeight

    ClockView {
        id: clock
        anchors.centerIn: parent
        anchors.alignWhenCentered: false
        opacity: root.showLyrics ? 0 : 1
        interactive: !root.showLyrics
        Behavior on opacity { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
    }

    LyricLine {
        objectName: "island-lyric-line"
        anchors.centerIn: parent
        anchors.alignWhenCentered: false
        maxWidth: root.lyricWidth - 32
        text: root.lyricsActive ? (LyricsService.currentLine || "\u266a") : ""
        opacity: root.showLyrics ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
    }
}
