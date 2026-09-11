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

    property string currentScheme
    property string currentVariant

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}scheme `.length);
    }

    function selector(item: var): string {
        return `${item.name} ${item.flavour}`;
    }

    function reload(): void {
        getSchemes.running = true;
    }

    list: schemes.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes
    keys: ["name", "flavour"]
    weights: [0.9, 0.1]

    Variants {
        id: schemes

        Scheme {}
    }

    Process {
        id: getSchemes

        running: true
        command: [System.actionScript, "theme-list"]
        stdout: StdioCollector {
            onStreamFinished: {
                schemes.model = JSON.parse(text).sort((a, b) => a.name.localeCompare(b.name));
            }
        }
    }

    component Scheme: QtObject {
        required property var modelData
        readonly property string name: modelData.name
        readonly property string flavour: modelData.flavour
        readonly property var colours: modelData.colours

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            System.run("theme", [name]);
        }
    }
}
