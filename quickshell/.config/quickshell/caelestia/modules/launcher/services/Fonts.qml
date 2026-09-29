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
    property var fontRows: []

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

        model: root.fontRows.map(font => font.name)
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
                    root.fontRows = JSON.parse(stdout.text);
                } catch (error) {
                    root.fontRows = [];
                    console.warn("Could not parse fonts:", error);
                }
            } else {
                root.fontRows = [];
                console.warn("Could not load fonts:", stderr.text);
            }
            if (root.refreshPending) {
                root.refreshPending = false;
                root.reload();
            }
        }
    }

    component Font: QtObject {
        required property string modelData
        readonly property var row: root.fontRows.find(font => font.name === modelData) ?? ({})
        readonly property string name: modelData
        readonly property string desc: current ? "Current font" : ""
        readonly property string icon: "font_download"
        readonly property bool current: row.current ?? false

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            if (!current)
                Quickshell.execDetached([`${Quickshell.env("HOME")}/bin/font`, "--", name]);
        }
    }
}
