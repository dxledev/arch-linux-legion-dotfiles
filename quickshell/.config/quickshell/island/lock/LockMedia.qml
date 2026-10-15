pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell.Widgets
import "../services"
import "../styles"
import "../components"

// A small record player. The album art is the record's label; it spins while music plays and the
// tonearm lowers onto it. Below: seek bar, transport, and a three-line lyric window. Every piece of
// information is optional, so each one has a quiet fallback instead of an empty gap.
Rectangle {
    id: root
    property string fontFamily: "Noto Sans"
    property int animationDuration: 180
    signal interacted()

    readonly property bool hasPlayer: MediaService.hasPlayer
    readonly property bool playing: hasPlayer && MediaService.isPlaying
    readonly property string trackTitle: (MediaService.title ?? "").trim()
    readonly property string trackArtist: (MediaService.artist ?? "").trim()
    readonly property string trackAlbum: (MediaService.album ?? "").trim()
    readonly property bool hasLength: MediaService.length > 0
    readonly property bool canSeek: hasLength && (MediaService.player?.canSeek ?? false)
    readonly property bool darkPalette: Theme.background.hslLightness < 0.5
    // Vinyl follows the palette: darker than the background on dark themes, the text colour on light ones.
    readonly property color vinyl: darkPalette ? Qt.darker(Theme.background, 1.5) : Qt.lighter(Theme.textPrimary, 1.15)
    readonly property color sheen: Qt.alpha(darkPalette ? Theme.textPrimary : Theme.background, 0.16)

    readonly property var lyricLines: LyricsService.lines ?? []
    readonly property int lyricIndex: LyricsService.currentIndex
    readonly property bool showLyrics: hasPlayer && LyricsService.hasLyrics
    readonly property string statusText: LyricsService.loading ? "Looking for lyrics…"
        : "No lyrics for this track, just the music."

    implicitWidth: 440
    implicitHeight: body.implicitHeight + 52
    radius: 30
    color: Qt.alpha(Theme.surface, 0.84)
    border.width: 1
    border.color: Qt.alpha(Theme.textPrimary, 0.07)
    Behavior on implicitHeight { NumberAnimation { duration: root.animationDuration; easing.type: Easing.OutCubic } }

    function line(index: int): string {
        return index >= 0 && index < lyricLines.length ? (lyricLines[index] ?? "").trim() : "";
    }

    // The service only fetches lyrics while someone is looking; each visible card is one viewer.
    property bool watching: false
    onVisibleChanged: syncWatching()
    Component.onCompleted: syncWatching()
    Component.onDestruction: if (watching) LyricsService.lockScreenViewers--
    function syncWatching(): void {
        if (visible === watching)
            return;
        watching = visible;
        LyricsService.lockScreenViewers += watching ? 1 : -1;
    }

    component Transport: Button {
        id: control
        property url iconSource
        property int glyphSize: 20
        property bool filled: false
        focusPolicy: Qt.NoFocus
        hoverEnabled: true
        onClicked: root.interacted()
        opacity: enabled ? 1 : 0.35
        background: Rectangle {
            radius: height / 2
            color: control.filled ? (control.down ? Theme.accentPressed : control.hovered ? Theme.accentHover : Theme.accent)
                : control.down ? Theme.buttonPressed : control.hovered ? Qt.alpha(Theme.textPrimary, 0.1) : "transparent"
        }
        contentItem: SvgIcon {
            source: control.iconSource
            size: control.glyphSize
            color: control.filled ? Theme.background : Theme.textPrimary
        }
    }

    Column {
        id: body
        x: 26
        y: 26
        width: parent.width - 52
        spacing: 20

        Item {
            id: deck
            width: parent.width
            height: 148

            // The record. One plain item rotates on the render thread; nothing in it is a layer.
            Item {
                id: platter
                y: 4
                width: 140
                height: 140

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: root.vinyl
                    border.width: 1
                    border.color: Qt.alpha(Theme.textPrimary, 0.14)
                }
                Repeater {
                    model: [14, 24, 34]
                    delegate: Rectangle {
                        required property int modelData
                        anchors.centerIn: parent
                        width: platter.width - modelData * 2
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.alpha(root.sheen, 0.5)
                    }
                }
                // Two highlights on opposite sides, so the spin reads even when the label is a flat colour.
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: root.sheen
                        strokeWidth: 3
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc { centerX: 70; centerY: 70; radiusX: 59; radiusY: 59; startAngle: -75; sweepAngle: 36 }
                    }
                    ShapePath {
                        strokeColor: root.sheen
                        strokeWidth: 3
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc { centerX: 70; centerY: 70; radiusX: 59; radiusY: 59; startAngle: 105; sweepAngle: 36 }
                    }
                }

                ClippingRectangle {
                    id: label
                    anchors.centerIn: parent
                    width: 68
                    height: 68
                    radius: width / 2
                    color: root.hasPlayer ? Theme.accent : Theme.surfaceVariant

                    Image {
                        id: art
                        anchors.fill: parent
                        source: root.hasPlayer ? MediaService.artUrl : ""
                        asynchronous: true
                        smooth: true
                        fillMode: Image.PreserveAspectCrop
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }
                    SvgIcon {
                        anchors.centerIn: parent
                        visible: art.status !== Image.Ready
                        source: root.hasPlayer ? "../assets/icons/music.svg" : "../assets/icons/music-off.svg"
                        size: 24
                        color: root.hasPlayer ? Theme.background : Theme.textMuted
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    visible: art.status === Image.Ready
                    width: 9
                    height: 9
                    radius: 4.5
                    color: Theme.background
                    border.width: 1
                    border.color: Qt.alpha(Theme.textPrimary, 0.25)
                }

                property real base: 0
                RotationAnimator {
                    id: spin
                    target: platter
                    from: platter.base
                    to: platter.base + 360
                    duration: 7000
                    loops: Animation.Infinite
                    running: root.playing && root.visible && root.animationDuration > 0
                    onStopped: platter.base = platter.rotation % 360
                }
            }

            // Tonearm: swings onto the record while playing and rests beside it otherwise.
            Item {
                id: arm
                x: 160
                y: 10
                rotation: root.playing ? 19 : -7
                Behavior on rotation { NumberAnimation { duration: root.animationDuration * 3; easing.type: Easing.OutCubic } }

                Rectangle {
                    x: -1.5
                    width: 3
                    height: 88
                    radius: 1.5
                    color: Theme.textMuted
                }
                Rectangle {
                    x: -6
                    y: 84
                    width: 12
                    height: 18
                    radius: 3
                    color: Theme.textSecondary
                }
                Rectangle {
                    x: -8
                    y: -8
                    width: 16
                    height: 16
                    radius: 8
                    color: Theme.surfaceVariant
                    border.width: 1
                    border.color: Qt.alpha(Theme.textPrimary, 0.2)
                }
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 198
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    objectName: "lock-media-title"
                    width: parent.width
                    text: !root.hasPlayer ? "Nothing playing" : root.trackTitle || "Unknown track"
                    color: Theme.textPrimary
                    font.family: root.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    visible: !root.hasPlayer || root.trackArtist !== ""
                    text: root.hasPlayer ? root.trackArtist : "Play something to start."
                    color: Theme.textSecondary
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    wrapMode: root.hasPlayer ? Text.NoWrap : Text.Wrap
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    visible: root.hasPlayer && root.trackAlbum !== ""
                    text: root.trackAlbum
                    color: Theme.textMuted
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
                Item { width: 1; height: 6; visible: root.hasPlayer }
                Text {
                    width: parent.width
                    visible: root.hasPlayer
                    text: (root.playing ? "Playing" : "Paused") + (MediaService.playerName ? " on " + MediaService.playerName : "")
                    color: root.playing ? Theme.accent : Theme.textMuted
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
        }

        Column {
            width: parent.width
            spacing: 2
            visible: root.hasPlayer

            SeekBar {
                width: parent.width
                progress: root.hasLength ? MediaService.position / MediaService.length : 0
                trackColor: Qt.alpha(Theme.textPrimary, 0.14)
                fillColor: Theme.accent
                barHeight: 5
                hoverBarHeight: 7
                radius: 3
                seekable: root.canSeek
                smoothDuration: 1000
                onSeekRequested: fraction => { MediaService.seek(fraction * MediaService.length); root.interacted(); }
            }
            Item {
                width: parent.width
                height: 16
                Text {
                    anchors.left: parent.left
                    text: MediaService.formatTime(MediaService.position)
                    color: Theme.textMuted
                    font.family: root.fontFamily
                    font.pixelSize: 11
                }
                Text {
                    anchors.right: parent.right
                    visible: root.hasLength
                    text: MediaService.formatTime(MediaService.length)
                    color: Theme.textMuted
                    font.family: root.fontFamily
                    font.pixelSize: 11
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 18
            visible: root.hasPlayer

            Transport {
                width: 46
                height: 46
                iconSource: "../assets/icons/player-skip-back.svg"
                enabled: MediaService.player?.canGoPrevious ?? false
                Accessible.name: "Previous track"
                onClicked: MediaService.previousTrack()
            }
            Transport {
                width: 58
                height: 58
                filled: true
                glyphSize: 24
                iconSource: root.playing ? "../assets/icons/player-pause.svg" : "../assets/icons/player-play.svg"
                enabled: MediaService.canTogglePlayback
                Accessible.name: root.playing ? "Pause" : "Play"
                onClicked: MediaService.togglePlayback()
            }
            Transport {
                width: 46
                height: 46
                iconSource: "../assets/icons/player-skip-forward.svg"
                enabled: MediaService.player?.canGoNext ?? false
                Accessible.name: "Next track"
                onClicked: MediaService.nextTrack()
            }
        }

        Item {
            id: lyrics
            objectName: "lock-lyrics"
            width: parent.width
            height: root.showLyrics ? 78 : 20
            visible: root.hasPlayer
            clip: true
            Behavior on height { NumberAnimation { duration: root.animationDuration; easing.type: Easing.OutCubic } }

            Text {
                anchors.fill: parent
                visible: !root.showLyrics
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.statusText
                color: Theme.textMuted
                font.family: root.fontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            Column {
                anchors.fill: parent
                visible: root.showLyrics
                spacing: 8

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.line(root.lyricIndex - 1)
                    color: Theme.textMuted
                    opacity: 0.7
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
                LyricLine {
                    width: parent.width
                    maxWidth: parent.width
                    fontSize: 16
                    // An intro or instrumental gap has no line yet; a note keeps the rhythm.
                    text: LyricsService.currentLine || "♪"
                    color: Theme.textPrimary
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.line(root.lyricIndex + 1)
                    color: Theme.textMuted
                    opacity: 0.7
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
        }
    }
}
