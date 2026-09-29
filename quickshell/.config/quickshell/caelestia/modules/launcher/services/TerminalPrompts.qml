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
    property var promptRows: []

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}terminal-prompt `.length);
    }

    function reload(): void {
        if (getPrompts.running)
            refreshPending = true;
        else
            getPrompts.running = true;
    }

    list: prompts.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes

    Variants {
        id: prompts

        model: root.promptRows.map(prompt => prompt.id)
        Prompt {}
    }

    Process {
        id: getPrompts

        running: true
        command: ["/usr/bin/bash", Quickshell.shellPath("integration/terminal-prompt")]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    root.promptRows = JSON.parse(stdout.text);
                } catch (error) {
                    root.promptRows = [];
                    console.warn("Could not parse prompts:", error);
                }
            } else {
                root.promptRows = [];
                console.warn("Could not load prompts:", stderr.text);
            }
            if (root.refreshPending) {
                root.refreshPending = false;
                root.reload();
            }
        }
    }

    component Prompt: QtObject {
        required property string modelData
        readonly property var row: root.promptRows.find(prompt => prompt.id === modelData) ?? ({})
        readonly property string name: row.name ?? ""
        readonly property string desc: current ? "Current prompt" : ""
        readonly property string icon: "terminal"
        readonly property bool current: row.current ?? false

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            if (!current)
                Quickshell.execDetached(["/usr/bin/bash", Quickshell.shellPath("integration/terminal-prompt"), "--apply", modelData]);
        }
    }
}
