pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import Caelestia.Config
import Caelestia.Models
import qs.utils

Searcher {
    id: root

    readonly property string appListPath: Quickshell.env("APP_LIST") || `${Paths.home}/.config/apps.list`
    readonly property string menuScript: Quickshell.env("MENU_APPS_SCRIPT") || `${Paths.home}/bin/menu-apps`
    readonly property string appListScript: Quickshell.shellPath("integration/app-list")
    property bool refreshPending: false
    property var configuredRows: []

    function launch(entry: var): void {
        appDb.incrementFrequency(entry.id);
        Quickshell.execDetached(["/usr/bin/bash", appListScript, "--launch", entry.launcher]);
    }

    function refresh(): void {
        refreshPending = true;
        if (!getApps.running) {
            refreshPending = false;
            getApps.running = true;
        }
    }

    function search(search: string): var {
        const prefix = GlobalConfig.launcher.specialPrefix;

        if (search.startsWith(`${prefix}i `)) {
            keys = ["id", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}c `)) {
            keys = ["categories", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}d `)) {
            keys = ["comment", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}e `)) {
            keys = ["execString", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}w `)) {
            keys = ["startupClass", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}g `)) {
            keys = ["genericName", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}k `)) {
            keys = ["keywords", "name"];
            weights = [0.9, 0.1];
        } else {
            keys = ["name"];
            weights = [1];

            if (!search.startsWith(`${prefix}t `))
                return query(search).map(e => e.entry);
        }

        const results = query(search.slice(prefix.length + 2)).map(e => e.entry);
        if (search.startsWith(`${prefix}t `))
            return results.filter(a => a.runInTerminal);
        return results;
    }

    function selector(item: var): string {
        return keys.map(k => item[k]).join(" ");
    }

    list: appDb.apps.slice().sort((a, b) => a.entry.listIndex - b.entry.listIndex)
    useFuzzy: GlobalConfig.launcher.useFuzzy.apps

    AppDb {
        id: appDb

        path: `${Paths.state}/apps.sqlite`
        favouriteApps: GlobalConfig.launcher.favouriteApps
        entries: configuredApps.instances
    }

    Variants {
        id: configuredApps
        model: root.configuredRows.map(row => row.launcher)

        QtObject {
            required property string modelData
            readonly property int listIndex: root.configuredRows.findIndex(row => row.launcher === modelData)
            readonly property var row: root.configuredRows[listIndex]
            readonly property string launcher: modelData
            readonly property string id: launcher.replace(/\.desktop$/, "")
            readonly property var desktopEntry: DesktopEntries.byId(id)
            readonly property string name: row?.name ?? launcher
            readonly property string icon: row?.icon ?? ""
            readonly property string comment: desktopEntry?.comment ?? ""
            readonly property string genericName: desktopEntry?.genericName ?? ""
            readonly property string execString: desktopEntry?.execString ?? launcher
            readonly property string startupClass: desktopEntry?.startupClass ?? ""
            readonly property list<string> categories: desktopEntry?.categories ?? []
            readonly property list<string> keywords: desktopEntry?.keywords ?? []
            readonly property bool runInTerminal: desktopEntry?.runInTerminal ?? false
        }
    }

    Variants {
        model: [root.appListPath, root.menuScript,
            `${Quickshell.env("XDG_CONFIG_HOME") || `${Paths.home}/.config`}/gtk-4.0/settings.ini`,
            `${Quickshell.env("XDG_CONFIG_HOME") || `${Paths.home}/.config`}/gtk-3.0/settings.ini`]

        FileView {
            required property string modelData
            path: modelData
            watchChanges: true
            onFileChanged: {
                reload();
                root.refresh();
            }
        }
    }

    Process {
        id: getApps
        running: true
        command: ["/usr/bin/bash", root.appListScript, "--list"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    root.configuredRows = JSON.parse(stdout.text);
                } catch (error) {
                    root.configuredRows = [];
                    console.warn("Could not parse app list:", error);
                }
            } else {
                root.configuredRows = [];
                console.warn("Could not load app list:", stderr.text);
            }
            if (root.refreshPending)
                root.refresh();
        }
    }
}
