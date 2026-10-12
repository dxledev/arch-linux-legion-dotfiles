pragma Singleton

import QtQuick

QtObject {
    readonly property var players: ({ values: [pausedPlayer, playingPlayer] })

    property QtObject pausedPlayer: QtObject {
        property string trackTitle: "Paused fixture"
        property string trackArtist: "Test"
        property string trackArtUrl: ""
        property int playbackState: MprisPlaybackState.Paused
        property int position: 0
        property int length: 120
        property bool canTogglePlaying: true
        property int toggleCount: 0
        function togglePlaying() {
            toggleCount++;
            playbackState = playbackState === MprisPlaybackState.Playing
                ? MprisPlaybackState.Paused : MprisPlaybackState.Playing;
        }
        function next() {}
        function previous() {}
    }

    property QtObject playingPlayer: QtObject {
        property string trackTitle: "Playing fixture"
        property string trackArtist: "Test"
        property string trackArtUrl: ""
        property int playbackState: MprisPlaybackState.Playing
        property int position: 0
        property int length: 180
        property bool canTogglePlaying: true
        property int toggleCount: 0
        function togglePlaying() {
            toggleCount++;
            playbackState = playbackState === MprisPlaybackState.Playing
                ? MprisPlaybackState.Paused : MprisPlaybackState.Playing;
        }
        function next() {}
        function previous() {}
    }
}
