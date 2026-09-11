pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils
import qs.integration

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear
    property var wallpaperQueue: []

    function queueWallpaper(path: string, persist: bool): void {
        if (!path)
            return;

        wallpaperQueue = [...wallpaperQueue.filter(job => job.persist), { path, persist }];
        wallpaperDebounce.restart();
    }

    function applyNextWallpaper(): void {
        if (applyWallpaper.running || !wallpaperQueue.length)
            return;

        const job = wallpaperQueue[0];
        wallpaperQueue = wallpaperQueue.slice(1);
        applyWallpaper.command = [System.actionScript, job.persist ? "wallpaper" : "wallpaper-preview", job.path];
        applyWallpaper.running = true;
    }

    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        System.run("next-wallpaper", []);
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;
        if (showPreview)
            previewPath = path;
        queueWallpaper(path, true);
    }

    function refresh(): void {
        currentWallpaper.running = true;
    }

    function preview(path: string): void {
        if (showPreview && previewPath === path)
            return;
        previewPath = path;
        showPreview = true;
        queueWallpaper(path, false);

        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        if (showPreview && previewPath !== actualCurrent)
            queueWallpaper(actualCurrent, false);
        showPreview = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    list: wallpapers.entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function preview(path: string): void {
            root.preview(path);
        }

        function stopPreview(): void {
            root.stopPreview();
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        target: "wallpaper"
    }

    Process {
        id: applyWallpaper

        onExited: (code, status) => {
            if (code !== 0) {
                console.warn("Wallpaper update failed:", code);
                root.refresh();
            }
            Qt.callLater(root.applyNextWallpaper);
        }
    }

    Timer {
        id: wallpaperDebounce
        interval: 50
        onTriggered: root.applyNextWallpaper()
    }

    Process {
        id: currentWallpaper
        running: true
        command: [System.actionScript, "wallpaper-path"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!applyWallpaper.running && !root.wallpaperQueue.length)
                    root.actualCurrent = text.trim() || root.fallback;
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images
    }

    Process {
        id: getPreviewColoursProc

        command: ["caelestia", "wallpaper", "-p", root.previewPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }
}
