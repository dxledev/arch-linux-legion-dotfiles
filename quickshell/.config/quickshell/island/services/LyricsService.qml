pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Caelestia.Services
import "../island"

// Synced lyrics for the active media player, backed by Caelestia's Lyrics service
// (LRCLIB / NetEase, shared from the common plugin directory). Only fetches while the
// floating lyrics card, the island lyric clock or a lock screen media card is showing.
//
// The backend forgets a track whenever it is asked about it again, and players re-send
// metadata on pause/resume, so results are kept here per track: a song that has been found
// once is never looked up (or lost) again, and a stuck lookup times out instead of
// spinning forever.
Singleton {
    id: root

    // Lock screen media cards currently on screen (one per display); lyrics are wanted while any shows.
    property int lockScreenViewers: 0
    readonly property bool active: IslandState.lyricsOpen || IslandState.lyricsClockMonitor !== "" || lockScreenViewers > 0
    readonly property var player: MediaService.player

    // What the card shows. Plain properties: the backend's notify signals are unreliable.
    property var lines: []
    property bool loading: false
    property bool hasLyrics: false
    property int currentIndex: -1
    // The line being sung right now, "" before the first line and in instrumental gaps.
    readonly property string currentLine: currentIndex >= 0 && currentIndex < lines.length ? (lines[currentIndex] ?? "").trim() : ""

    // Playback position in seconds, polled finely while the card is open (MediaService is 1 Hz).
    property real position: 0

    // key ("artist|title") -> { lines: [...], times: [...] }, in insertion order.
    property var cache: ({})
    property var cacheOrder: []
    property string currentKey: ""
    property string requestedKey: ""
    property bool fetching: false
    property bool sawLoading: false
    property bool lateWatch: false
    property double fetchStart: 0
    property double failedAt: 0

    readonly property int fetchTimeout: 12000
    readonly property int retryAfter: 20000

    // True while the island on this monitor really shows a lyric line instead of its clock.
    function clockShowsLyrics(monitorName) {
        return monitorName !== "" && IslandState.lyricsClockMonitor === monitorName
            && MediaService.hasPlayer && root.hasLyrics
    }

    function keyFor(player) {
        return ((player.trackArtist ?? "") + "|" + (player.trackTitle ?? "")).toLowerCase();
    }

    // The backend returns plain lines plus a start time per line (also what its own click-to-seek uses).
    function store(key) {
        const lyrics = Lyrics.lyrics;
        const count = lyrics.length;
        if (count === 0)
            return;

        const times = [];
        for (let i = 0; i < count; i++) {
            const t = Lyrics.timeForIndex(i);
            // Keep the list sorted so lookups can bisect; unknown stamps never match.
            times.push(isFinite(t) ? Math.max(t, i > 0 ? times[i - 1] : 0) : Infinity);
        }

        const lines = [];
        for (let i = 0; i < count; i++)
            lines.push(lyrics[i]);

        if (!root.cache[key]) {
            root.cacheOrder.push(key);
            if (root.cacheOrder.length > 40)
                delete root.cache[root.cacheOrder.shift()];
        }
        root.cache[key] = { lines: lines, times: times };
    }

    function indexAt(times, seconds) {
        let low = 0;
        let high = times.length - 1;
        let found = -1;
        while (low <= high) {
            const mid = (low + high) >> 1;
            if (times[mid] <= seconds) {
                found = mid;
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }
        return found;
    }

    // Seeks the player to the start of a lyric line (click-to-sync, as in Caelestia's lyric list).
    function seekToLine(index) {
        const entry = root.cache[root.currentKey];
        const player = root.player;
        if (!entry || !player || !player.canSeek || !isFinite(entry.times[index] ?? Infinity))
            return;

        // A hair past the stamp so the index lands on this line, not the previous one.
        root.seekTo(entry.times[index] + 0.05);
    }

    // Seeks the active player and updates the card immediately instead of on the next poll.
    function seekTo(seconds) {
        MediaService.seek(seconds);
        root.position = seconds;
        root.refresh();
    }

    function finishFetch(timedOut) {
        root.fetching = false;
        if (!timedOut && Lyrics.hasLyrics && root.requestedKey === root.currentKey) {
            root.store(root.requestedKey);
            root.lateWatch = false;
        } else {
            root.failedAt = Date.now();
            root.lateWatch = timedOut;
        }
    }

    function refresh() {
        if (root.fetching) {
            if (Lyrics.loading)
                root.sawLoading = true;
            const age = Date.now() - root.fetchStart;
            if (!Lyrics.loading && (root.sawLoading || age > 3000))
                root.finishFetch(false);
            else if (age > root.fetchTimeout)
                root.finishFetch(true);
        } else if (root.lateWatch && !root.cache[root.currentKey] && root.requestedKey === root.currentKey
                   && Lyrics.hasLyrics && !Lyrics.loading) {
            // A lookup that outlived its timeout finally answered.
            root.store(root.requestedKey);
            root.lateWatch = false;
        }

        const entry = root.cache[root.currentKey] ?? null;
        const lines = entry ? entry.lines : [];
        if (root.lines !== lines)
            root.lines = lines;
        root.hasLyrics = entry !== null;
        root.loading = root.fetching && entry === null;
        root.currentIndex = entry ? root.indexAt(entry.times, root.position) : -1;
    }

    // Track metadata arrives piecemeal (title before album and length), so settle before fetching.
    function sync() {
        const player = root.player;
        if (!root.active || !player) {
            root.currentKey = "";
            root.refresh();
            return;
        }

        const key = root.keyFor(player);
        root.currentKey = key;

        const known = root.cache[key] !== undefined;
        const sameRequest = key === root.requestedKey
            && (root.fetching || Date.now() - root.failedAt < root.retryAfter);

        if (!known && !sameRequest && player.trackTitle !== "") {
            root.requestedKey = key;
            root.fetching = true;
            root.sawLoading = false;
            root.lateWatch = false;
            root.fetchStart = Date.now();
            Lyrics.setTrack(player.trackArtist, player.trackTitle, player.trackAlbum, player.length);
        }
        root.refresh();
    }

    Timer {
        id: settle

        interval: 300
        onTriggered: root.sync()
    }

    Connections {
        target: root.player
        ignoreUnknownSignals: true

        function onTrackTitleChanged() { settle.restart() }
        function onTrackArtistChanged() { settle.restart() }
        function onTrackAlbumChanged() { settle.restart() }
        function onLengthChanged() { settle.restart() }
    }

    Connections {
        target: Lyrics

        function onLyricsChanged() { root.refresh() }
        function onHasLyricsChanged() { root.refresh() }
        function onLoadingChanged() { root.refresh() }
    }

    // Nothing left to sing along to: hand the clock back instead of leaving a stale request behind.
    Connections {
        target: MediaService

        function onHasPlayerChanged() {
            if (!MediaService.hasPlayer)
                IslandState.lyricsClockMonitor = ""
        }
    }

    onActiveChanged: settle.restart()
    onPlayerChanged: settle.restart()

    Timer {
        interval: 250
        repeat: true
        triggeredOnStart: true
        running: root.active && root.player !== null

        onTriggered: {
            const player = root.player;
            if (!player)
                return;
            if (player.playbackState === MprisPlaybackState.Playing)
                player.positionChanged();
            root.position = player.position;

            // Re-ask if the track changed without a signal, or a failed lookup is due a retry.
            if (root.keyFor(player) !== root.currentKey || (!root.hasLyrics && !root.fetching
                    && Date.now() - root.failedAt > root.retryAfter))
                root.sync();
            else
                root.refresh();
        }
    }
}
