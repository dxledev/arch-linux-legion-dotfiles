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

    function setFilter(theme) { reload(); }
    function apply(path) { ThemeService.execute(["wallpaper", path]); }
    function reload() {
        if (scanner.running) { pending = true; return; }
        scanner.running = true;
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
            } else { ThemeService.error = stderr.text.trim(); }
            if (root.pending) { root.pending = false; Qt.callLater(root.reload); }
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
