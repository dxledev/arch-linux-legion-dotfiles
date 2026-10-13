pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "MediaSelection.js" as MediaSelection

Singleton {
    id: root

    property var player: null

    property string title: ""
    property string artist: ""
    property string artUrl: ""
    property string album: ""
    property string playerName: ""

    property bool isPlaying: false

    property int position: 0
    property int length: 0

    property url icon: Qt.resolvedUrl("../assets/icons/music.svg")

    property string subtitle:
        hasPlayer
            ? title
            : "Nothing Playing"

    readonly property bool hasPlayer: player !== null
    readonly property bool canTogglePlayback: hasPlayer && player.canTogglePlaying
    readonly property bool isPaused: hasPlayer && player.playbackState === MprisPlaybackState.Paused

    readonly property int playbackPlaying: MprisPlaybackState.Playing

    function updatePlayer() {

        const selected = MediaSelection.selectPlayer(Mpris.players.values, player, playbackPlaying)
        if (!selected) {

            player = null

            title = ""
            artist = ""
            artUrl = ""
            album = ""
            playerName = ""

            isPlaying = false
            position = 0
            length = 0

            return
        }

        if (player !== selected) {
            player = selected
            artUrl = ""
            length = 0
        }

        title = player.trackTitle
        artist = player.trackArtist
        album = player.trackAlbum
        playerName = player.identity

        // Keep the last valid artwork.
        if (player.trackArtUrl !== "")
            artUrl = player.trackArtUrl

        isPlaying = player.playbackState === playbackPlaying

        position = player.position

        if (player.length > position + 5)
            length = player.length

    }

    function formatTime(seconds) {

        if (!seconds || seconds < 0)
            return "0:00"

        let minutes = Math.floor(seconds / 60)
        let secs = Math.floor(seconds % 60)

        return minutes + ":" + (secs < 10 ? "0" + secs : secs)
    }

    function togglePlayback() {

        updatePlayer()
        if (!canTogglePlayback)
            return

        player.togglePlaying()
    }

    // Seeks the active player to an absolute position in seconds.
    function seek(seconds) {

        if (!player || !player.canSeek)
            return

        const target = Math.max(0, length > 0 ? Math.min(seconds, length) : seconds)

        player.position = target
        position = target
    }

    function nextTrack() {

        if (!player)
            return

        player.next()
    }

    function previousTrack() {

        if (!player)
            return

        player.previous()
    }

    Timer {
        interval: 1000
        repeat: true
        running: true

        onTriggered: root.updatePlayer()
    }

    Connections {

        target: player

        function onTrackTitleChanged() {
            root.title = player.trackTitle
            root.length = 0
        }

        function onTrackArtistChanged() {
            root.artist = player.trackArtist
        }

        function onTrackAlbumChanged() {
            root.album = player.trackAlbum
        }

        function onTrackArtUrlChanged() {

            if (player.trackArtUrl !== "")
                root.artUrl = player.trackArtUrl
        }

        function onPlaybackStateChanged() {
            root.isPlaying =
                player.playbackState === root.playbackPlaying
        }

        function onPositionChanged() {
            root.position = player.position
        }

        function onLengthChanged() {

            if (!player)
                return

            if (player.length > root.position + 5)
                root.length = player.length
        }
    }

    Component.onCompleted: updatePlayer()
}
