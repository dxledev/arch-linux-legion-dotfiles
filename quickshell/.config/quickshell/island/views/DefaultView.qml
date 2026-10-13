import QtQuick
import Quickshell
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
    // Settings -> Media sets the narrowest the Island gets while lyrics stand in for the clock.
    // A line that does not fit widens it, up to maxLyricWidth, and the next shorter line lets it
    // settle back; beyond maxLyricWidth the line scrolls.
    readonly property real lyricWidth: ThemeService.settings.lyricsIslandMinWidth ?? 340
    readonly property real lyricPadding: 32
    readonly property real screenWidth: (QsWindow.window as QsWindow)?.screen?.width ?? 1920
    readonly property real maxLyricWidth: Math.max(lyricWidth, Math.round(screenWidth * 0.6))

    implicitWidth: showLyrics
        ? Math.min(maxLyricWidth, Math.max(clockWidth, lyricWidth, lyric.contentWidth + lyricPadding))
        : clockWidth
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
        id: lyric
        objectName: "island-lyric-line"
        anchors.centerIn: parent
        anchors.alignWhenCentered: false
        maxWidth: root.maxLyricWidth - root.lyricPadding
        text: root.lyricsActive ? (LyricsService.currentLine || "\u266a") : ""
        opacity: root.showLyrics ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
    }
}
