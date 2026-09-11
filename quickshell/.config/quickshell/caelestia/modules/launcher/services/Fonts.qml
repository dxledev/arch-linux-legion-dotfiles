pragma Singleton

import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.utils

Searcher {
    id: root

    property bool refreshPending: false

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}fonts `.length);
    }

    function reload(): void {
        if (getFonts.running)
            refreshPending = true;
        else
            getFonts.running = true;
    }

    list: fonts.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes

    Variants {
        id: fonts

        Font {}
    }

    Process {
        id: getFonts

        running: true
        command: ["/usr/bin/bash", Quickshell.shellPath("integration/font-list")]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    fonts.model = JSON.parse(stdout.text);
                } catch (error) {
                    fonts.model = [];
                    console.warn("Could not parse fonts:", error);
                }
            } else {
                fonts.model = [];
                console.warn("Could not load fonts:", stderr.text);
            }
            if (root.refreshPending) {
                root.refreshPending = false;
                root.reload();
            }
        }
    }

    component Font: QtObject {
        required property var modelData
        readonly property string name: modelData.name
        readonly property string desc: current ? "Current font" : ""
        readonly property string icon: "font_download"
        readonly property bool current: modelData.current

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            if (!current)
                Quickshell.execDetached([`${Quickshell.env("HOME")}/bin/font`, "--", name]);
        }
    }
}
