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
                    prompts.model = JSON.parse(stdout.text);
                } catch (error) {
                    prompts.model = [];
                    console.warn("Could not parse prompts:", error);
                }
            } else {
                prompts.model = [];
                console.warn("Could not load prompts:", stderr.text);
            }
            if (root.refreshPending) {
                root.refreshPending = false;
                root.reload();
            }
        }
    }

    component Prompt: QtObject {
        required property var modelData
        readonly property string name: modelData.name
        readonly property string desc: current ? "Current prompt" : ""
        readonly property string icon: "terminal"
        readonly property bool current: modelData.current

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            if (!current)
                Quickshell.execDetached(["/usr/bin/bash", Quickshell.shellPath("integration/terminal-prompt"), "--apply", modelData.id]);
        }
    }
}
