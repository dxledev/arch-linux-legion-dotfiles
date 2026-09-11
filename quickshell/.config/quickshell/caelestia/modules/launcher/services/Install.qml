pragma Singleton

import ".."
import QtQuick
import Quickshell
import Caelestia.Config

Singleton {
    id: root

    readonly property string prefix: `${GlobalConfig.launcher.actionPrefix}install `
    property var installers: [
        { name: "Arch", icon: "download", description: "Install Arch packages", script: "launch-pacman-tui" },
        { name: "AUR", icon: "inventory_2", description: "Install AUR packages", script: "launch-pacman-aur-tui" },
        { name: "Fonts", icon: "font_download", description: "Install fonts", script: "launch-pacman-font-tui" }
    ]

    function query(text: string): var {
        const search = text.slice(prefix.length);
        const items = install.instances;
        const words = search.toLowerCase().trim().split(/\s+/);
        return [...items].filter(item => words.every(word => `${item.name} ${item.desc}`.toLowerCase().includes(word)));
    }

    Variants {
        id: install
        model: root.installers
        Entry {}
    }

    component Entry: QtObject {
        required property var modelData
        readonly property string name: modelData.name
        readonly property string desc: modelData.description
        readonly property string icon: modelData.icon

        function onClicked(list: AppList): void {
            if (modelData.script) {
                list.screenState.launcher = false;
                Quickshell.execDetached([`${Quickshell.env("HOME")}/bin/${modelData.script}`]);
            }
        }
    }
}
