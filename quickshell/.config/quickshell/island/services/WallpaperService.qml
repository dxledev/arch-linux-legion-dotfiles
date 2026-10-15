pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property ListModel allWallpapers: ListModel {}
    readonly property ListModel themeWallpapers: allWallpapers
    readonly property ListModel currentModel: allWallpapers
    readonly property bool themeOnly: true
    property bool pending: false
    property string directory: ""
    property string watchedDirectory: ""
    property string snapshotDirectory: ""
    property bool snapshotPending: false

    // Favorites live in Island's settings; the pending copy keeps quick consecutive toggles from
    // overwriting each other while the setting round-trips through the state file.
    property var pendingFavorites: null
    readonly property var favorites: pendingFavorites ?? sanitizeFavorites(ThemeService.settings.wallpaperFavorites)
    readonly property var favoriteSet: {
        const set = {};
        for (const path of favorites) set[path] = true;
        return set;
    }
    // Favorites-only filter and the sort order are saved settings too; the pending copies keep the
    // header buttons responsive while the setting round-trips.
    property var pendingFavoritesOnly: null
    readonly property bool favoritesOnly: pendingFavoritesOnly ?? (ThemeService.settings.wallpaperFavoritesOnly === true)
    readonly property var sortModes: ["name-asc", "name-desc", "added-desc", "added-asc"]
    readonly property var sortLabels: ({
        "name-asc": "Name (A–Z)", "name-desc": "Name (Z–A)",
        "added-desc": "Recently added", "added-asc": "Oldest first"
    })
    property var pendingSort: null
    readonly property string sortMode: {
        const value = pendingSort ?? ThemeService.settings.wallpaperSort;
        return sortModes.includes(value) ? value : "name-asc";
    }

    function sanitizeFavorites(value) {
        return Array.isArray(value) ? value.filter(path => typeof path === "string" && path.startsWith("/")) : [];
    }
    function isFavorite(path) { return favoriteSet[path] === true; }
    readonly property int favoritesLimit: {
        const value = Math.round(Number(ThemeService.settings.wallpaperFavoritesLimit));
        return isFinite(value) ? Math.max(5, Math.min(value, 20)) : 10;
    }
    // Shown briefly by the selector when a star is refused because the limit is reached.
    property string favoritesNotice: ""

    function toggleFavorite(path) {
        if (!ThemeService.ready) return;
        const next = favorites.filter(entry => entry !== path);
        if (next.length === favorites.length) {
            // Removing is always allowed, even when a lowered limit leaves more favorites than it permits.
            if (favorites.length >= favoritesLimit) {
                favoritesNotice = "Favorites are limited to " + favoritesLimit + ". Remove one, or raise the limit in Settings → Wallpaper.";
                noticeTimer.restart();
                return;
            }
            next.push(path);
        }
        pendingFavorites = next;
        ThemeService.setSetting("wallpaperFavorites", JSON.stringify(next));
    }
    function toggleFavoritesOnly() {
        pendingFavoritesOnly = !favoritesOnly;
        ThemeService.setSetting("wallpaperFavoritesOnly", pendingFavoritesOnly);
    }
    function setSort(mode) {
        if (!sortModes.includes(mode) || mode === sortMode) return;
        pendingSort = mode;
        ThemeService.setSetting("wallpaperSort", mode);
    }

    Timer {
        id: noticeTimer
        interval: 3500
        onTriggered: root.favoritesNotice = ""
    }

    Connections {
        target: ThemeService
        function onSettingsChanged() {
            const saved = root.sanitizeFavorites(ThemeService.settings.wallpaperFavorites);
            if (!ThemeService.busy && ThemeService.pending.length === 0) {
                if (JSON.stringify(saved) === JSON.stringify(root.pendingFavorites)) root.pendingFavorites = null;
                if ((ThemeService.settings.wallpaperFavoritesOnly === true) === root.pendingFavoritesOnly)
                    root.pendingFavoritesOnly = null;
                if (ThemeService.settings.wallpaperSort === root.pendingSort) root.pendingSort = null;
            }
        }
        function onErrorChanged() {
            if (ThemeService.error) { root.pendingFavorites = null; root.pendingFavoritesOnly = null; root.pendingSort = null; }
        }
    }

    function setFilter(theme) { reload(); }
    function apply(path) { ThemeService.execute(["wallpaper", path]); }
    function rename(path, stem) { ThemeService.execute(["rename-wallpaper", path, stem]); }
    function remove(paths) { if (paths.length > 0) ThemeService.execute(["delete-wallpapers", ...paths]); }
    function reload() {
        if (scanner.running) { pending = true; return; }
        scanner.running = true;
    }

    function takeSnapshot() {
        if (!directory) return;
        if (snapshot.running) { snapshotPending = true; return; }
        snapshotDirectory = directory;
        snapshot.command = [Quickshell.shellDir + "/scripts/cache-wallpapers.sh", directory];
        snapshot.running = true;
    }

    function startWatcher() {
        if (!directory || watcher.running) return;
        watchedDirectory = directory;
        watcher.command = [Quickshell.shellDir + "/scripts/cache-wallpapers.sh", directory, "--watch"];
        watcher.running = true;
    }

    function update(rows) {
        for (let index = 0; index < rows.length; index++) {
            const row = rows[index];
            if (index >= allWallpapers.count) allWallpapers.append(row);
            else if (allWallpapers.get(index).path !== row.path) allWallpapers.set(index, row);
            else {
                if (allWallpapers.get(index).thumbnail !== row.thumbnail)
                    allWallpapers.setProperty(index, "thumbnail", row.thumbnail);
                if (allWallpapers.get(index).added !== row.added)
                    allWallpapers.setProperty(index, "added", row.added);
            }
        }
        if (allWallpapers.count > rows.length)
            allWallpapers.remove(rows.length, allWallpapers.count - rows.length);
    }

    Process {
        id: scanner
        command: [ThemeService.controller, "wallpaper-directory"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: function(code) {
            if (code === 0) {
                root.directory = stdout.text.trim();
                if (watcher.running && root.directory !== root.watchedDirectory)
                    watcher.running = false;
                else root.startWatcher();
                // The watcher only polls every couple of seconds; a one-shot scan makes deletions show at once.
                root.takeSnapshot();
            } else { ThemeService.error = stderr.text.trim(); }
            if (root.pending) { root.pending = false; Qt.callLater(root.reload); }
        }
    }
    Process {
        id: snapshot
        stdout: StdioCollector {}
        onExited: function(code) {
            // A scan that began before the theme switched belongs to the old directory.
            if (code === 0 && root.snapshotDirectory === root.directory) {
                try { root.update(JSON.parse(stdout.text)); } catch (err) {}
            }
            if (root.snapshotPending) { root.snapshotPending = false; Qt.callLater(root.takeSnapshot); }
        }
    }
    Process {
        id: watcher
        stdout: SplitParser {
            onRead: function(data) {
                try { root.update(JSON.parse(data)); }
                catch (err) { ThemeService.error = String(err); }
            }
        }
        stderr: StdioCollector {}
        onExited: function(code) {
            if (root.directory !== root.watchedDirectory) Qt.callLater(root.startWatcher);
            else if (code !== 0) ThemeService.error = stderr.text.trim();
        }
    }
    Component.onCompleted: reload()
}
