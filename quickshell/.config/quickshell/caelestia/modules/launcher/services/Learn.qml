pragma Singleton

import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

Singleton {
    id: root

    readonly property string prefix: `${GlobalConfig.launcher.actionPrefix}learn `
    property var entries: [
        { name: "Keybindings", icon: "keyboard", submenu: "keybindings", description: "Desktop shortcuts" },
        { name: "Hyprland", icon: "desktop_windows", url: "https://wiki.hypr.land/Configuring" },
        { name: "Arch", icon: "computer", url: "https://wiki.archlinux.org/title/Main_page" },
        { name: "Neovim", icon: "code", submenu: "neovim", description: "Neovim shortcuts" },
        { name: "Lazyvim", icon: "code", url: "https://www.lazyvim.org/keymaps" },
        { name: "Bash", icon: "terminal", url: "https://devhints.io/bash" },
        { name: "Git", icon: "account_tree", url: "https://git-scm.com/cheat-sheet" }
    ]

    function query(text: string): var {
        let search = text.slice(prefix.length);
        let items = menu.instances;
        for (const section of ["keybindings", "neovim"]) {
            if (search.startsWith(`${section} `)) {
                items = section === "keybindings" ? keybindings.instances : neovim.instances;
                search = search.slice(section.length + 1);
                break;
            }
        }
        const words = search.toLowerCase().trim().split(/\s+/);
        return [...items].filter(item => words.every(word => `${item.name} ${item.desc}`.toLowerCase().includes(word)));
    }

    function reload(): void {
        bindingsProcess.running = true;
        neovimProcess.running = true;
    }

    function loadRows(process: var, variants: var, exitCode: int): void {
        if (exitCode !== 0) {
            variants.model = [{ name: "Could not load shortcuts", description: process.stderr.text.trim(), icon: "error" }];
            console.warn("Could not load Learn shortcuts:", process.stderr.text);
            return;
        }
        try {
            variants.model = JSON.parse(process.stdout.text);
        } catch (error) {
            console.warn("Could not parse Learn shortcuts:", error);
        }
    }

    Variants {
        id: menu
        model: root.entries
        Entry {}
    }

    Variants {
        id: keybindings
        Entry {}
    }

    Variants {
        id: neovim
        Entry {}
    }

    Process {
        id: bindingsProcess
        command: ["/usr/bin/bash", Quickshell.shellPath("integration/learn-list"), "keybindings"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: exitCode => root.loadRows(bindingsProcess, keybindings, exitCode)
    }

    Process {
        id: neovimProcess
        command: ["/usr/bin/bash", Quickshell.shellPath("integration/learn-list"), "neovim"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: exitCode => root.loadRows(neovimProcess, neovim, exitCode)
    }

    component Entry: QtObject {
        required property var modelData
        readonly property string name: modelData.name
        readonly property string desc: modelData.description ?? modelData.url ?? ""
        readonly property string icon: modelData.icon ?? "keyboard"

        function onClicked(list: AppList): void {
            if (modelData.submenu) {
                list.search.text = `${root.prefix}${modelData.submenu} `;
            } else if (modelData.url) {
                list.screenState.launcher = false;
                Quickshell.execDetached([`${Quickshell.env("HOME")}/bin/launch-web-app`, modelData.url]);
            }
        }
    }
}
