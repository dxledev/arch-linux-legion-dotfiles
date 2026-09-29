pragma Singleton

import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.utils
import qs.integration
import qs.services

Searcher {
    id: root

    property bool refreshPending: false
    property var themeRows: []

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}theme `.length);
    }

    function reload(): void {
        if (getThemes.running)
            refreshPending = true;
        else
            getThemes.running = true;
    }

    list: themes.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes

    Variants {
        id: themes

        model: root.themeRows.map(theme => theme.id)
        Theme {}
    }

    Process {
        id: getThemes

        running: true
        command: ["/usr/bin/bash", Quickshell.shellPath("integration/theme-list"), "--list"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    root.themeRows = JSON.parse(stdout.text);
                } catch (error) {
                    root.themeRows = [];
                    console.warn("Could not parse themes:", error);
                }
            } else {
                root.themeRows = [];
                console.warn("Could not load themes:", stderr.text);
            }
            if (root.refreshPending) {
                root.refreshPending = false;
                root.reload();
            }
        }
    }

    component Theme: QtObject {
        required property string modelData
        readonly property var row: root.themeRows.find(theme => theme.id === modelData) ?? ({})
        readonly property string name: row.name ?? ""
        readonly property string themeId: modelData
        readonly property string icon: row.icon ?? ""
        readonly property string iconType: row.iconType ?? "image"
        readonly property bool current: row.current ?? false
        readonly property bool applied: row.applied ?? false
        readonly property bool dynamic: row.dynamic ?? false

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            if (current)
                return;
            ThemeSwitch.request(themeId, dynamic, applied);
        }
    }
}
