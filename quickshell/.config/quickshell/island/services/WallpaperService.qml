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

    function setFilter(theme) { reload(); }
    function apply(path) { ThemeService.execute(["wallpaper", path]); }
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
            else if (allWallpapers.get(index).thumbnail !== row.thumbnail)
                allWallpapers.setProperty(index, "thumbnail", row.thumbnail);
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
