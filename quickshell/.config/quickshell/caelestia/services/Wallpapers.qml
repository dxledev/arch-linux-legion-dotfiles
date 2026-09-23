pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils
import qs.integration
import "../utils/scripts/wallpaper-names.js" as WallpaperNames

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")
    readonly property string startupWallpaper: `${System.configHome}/themes/.caelestia-use/wallpaper.png`
    readonly property string dynamicDirectory: Quickshell.env("CAELESTIA_DYNAMIC_WALLPAPERS_DIR") || `${Paths.home}/files/pictures/wallpapers/dynamic`
    readonly property string requestedDirectory: Colours.source === "dynamic" ? dynamicDirectory : Paths.wallsdir

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent: startupWallpaper
    property bool previewColourLock
    property bool pendingPreviewClear
    property var wallpaperQueue: []
    property string directory
    property string themePath
    property bool refreshPending: false
    property bool applyPersists: false
    property bool slideshowEnabled: false
    property bool slideshowStateLoaded: false

    function displayName(path: string): string {
        return WallpaperNames.displayName(path);
    }

    function categoryName(category: string): string {
        return WallpaperNames.titleCase(category);
    }

    function compare(a: FileSystemEntry, b: FileSystemEntry): real {
        return WallpaperNames.compare(a, b);
    }

    function updateState(state: var): void {
        const themeChanged = themePath !== state.theme || directory !== state.directory;
        if (themeChanged) {
            const restoreWallpaper = showPreview || applyWallpaper.running;
            showPreview = false;
            previewPath = "";
            previewColourLock = false;
            pendingPreviewClear = false;
            Colours.showPreview = false;
            wallpaperQueue = [];
            actualCurrent = state.wallpaper || fallback;
            themePath = state.theme;
            directory = state.directory;
            if (restoreWallpaper)
                queueWallpaper(actualCurrent, false);
        } else if (!applyWallpaper.running && !wallpaperQueue.length) {
            actualCurrent = state.wallpaper || fallback;
        }
    }

    function queueWallpaper(path: string, persist: bool): void {
        if (!path)
            return;

        wallpaperQueue = [...wallpaperQueue.filter(job => job.persist),
            {
                path,
                persist
            }
        ];
        wallpaperDebounce.restart();
    }

    function applyNextWallpaper(): void {
        if (applyWallpaper.running || !wallpaperQueue.length)
            return;

        const job = wallpaperQueue[0];
        wallpaperQueue = wallpaperQueue.slice(1);
        applyPersists = job.persist;
        applyWallpaper.command = [System.actionScript, job.persist ? "wallpaper" : "wallpaper-preview", job.path];
        applyWallpaper.running = true;
    }

    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(directory.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        System.run("next-wallpaper", []);
    }

    function cycleWallpaper(direction: int): void {
        const entries = root.list;
        if (!entries.length)
            return;

        const currentIndex = entries.findIndex(entry => entry.path === root.actualCurrent);
        const baseIndex = currentIndex >= 0 ? currentIndex : direction > 0 ? -1 : 0;
        const targetIndex = (baseIndex + direction + entries.length) % entries.length;
        root.setWallpaper(entries[targetIndex].path);
    }

    function toggleSlideshow(): bool {
        slideshowEnabled = !slideshowEnabled;
        slideshowStorage.setText(JSON.stringify({ enabled: slideshowEnabled }));
        if (slideshowEnabled)
            cycleWallpaper(1);
        return slideshowEnabled;
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;
        if (showPreview)
            previewPath = path;
        queueWallpaper(path, true);
    }

    function refresh(): void {
        if (currentWallpaper.running)
            refreshPending = true;
        else
            currentWallpaper.running = true;
    }

    function preview(path: string): void {
        if (!directory || !path.startsWith(directory + "/"))
            return;
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

    list: [...wallpapers.entries].sort((a, b) => root.compare(a, b))
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

        function next(): void {
            root.cycleWallpaper(1);
        }

        function previous(): void {
            root.cycleWallpaper(-1);
        }

        function toggleSlideshow(): bool {
            return root.toggleSlideshow();
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        target: "wallpaper"
    }

    Timer {
        interval: System.wallpaperSlideshowIntervalSeconds * 1000
        running: root.slideshowStateLoaded && root.slideshowEnabled
        repeat: true
        onTriggered: root.cycleWallpaper(1)
    }

    FileView {
        id: slideshowStorage

        path: `${Paths.state}/wallpaper-slideshow.json`
        printErrors: false

        onLoaded: {
            try {
                const state = JSON.parse(text());
                root.slideshowEnabled = state.enabled === true;
            } catch (error) {
                console.warn("Unable to load wallpaper slideshow state:", error);
                root.slideshowEnabled = false;
            }

            const shouldAdvance = !root.slideshowStateLoaded && root.slideshowEnabled;
            root.slideshowStateLoaded = true;
            if (shouldAdvance)
                Qt.callLater(() => root.cycleWallpaper(1));
        }

        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("Unable to load wallpaper slideshow state:", error);
            root.slideshowStateLoaded = true;
        }
    }

    Process {
        id: applyWallpaper

        onExited: (code, status) => {
            if (code !== 0) {
                console.warn("Wallpaper update failed:", code);
                root.refresh();
            } else if (root.applyPersists) {
                root.previewColourLock = false;
            }
            root.applyPersists = false;
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
        command: [System.actionScript, "wallpaper-state", root.requestedDirectory]
        onExited: {
            if (root.refreshPending) {
                root.refreshPending = false;
                Qt.callLater(root.refresh);
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.updateState(JSON.parse(text));
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Connections {
        target: Colours
        function onSourceChanged(): void {
            root.refresh();
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: root.directory
        filter: FileSystemModel.Images
    }

    Process {
        id: getPreviewColoursProc

        command: [Quickshell.shellPath("integration/shell-theme"), "preview", root.previewPath]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }
}
