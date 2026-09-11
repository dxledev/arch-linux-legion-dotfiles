pragma Singleton

import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.utils
import qs.integration

Searcher {
    id: root

    property bool refreshPending: false

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
                    themes.model = JSON.parse(stdout.text);
                } catch (error) {
                    themes.model = [];
                    console.warn("Could not parse themes:", error);
                }
            } else {
                themes.model = [];
                console.warn("Could not load themes:", stderr.text);
            }
            if (root.refreshPending) {
                root.refreshPending = false;
                root.reload();
            }
        }
    }

    component Theme: QtObject {
        required property var modelData
        readonly property string name: modelData.name
        readonly property string themeId: modelData.id
        readonly property string icon: modelData.icon
        readonly property bool current: modelData.current

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            if (!current)
                System.run("theme", [themeId]);
        }
    }
}
