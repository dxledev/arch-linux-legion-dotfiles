pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configHome: {
        const xdgConfigHome = Quickshell.env("XDG_CONFIG_HOME")
        return xdgConfigHome || Quickshell.env("HOME") + "/.config"
    }
    readonly property string family: {
        const ghosttyFamily = root.readGhosttyFamily(ghosttyConfig.text())
        return ghosttyFamily || root.readAlacrittyFamily(alacrittyConfig.text()) || "monospace"
    }

    function readGhosttyFamily(contents: string): string {
        const match = contents.match(/^[ \t]*font-family[ \t]*=[ \t]*"?([^"\r\n]+)"?[ \t]*$/m)
        return match ? match[1].trim() : ""
    }

    function readAlacrittyFamily(contents: string): string {
        let inNormalSection = false

        for (const line of contents.split(/\r?\n/)) {
            const value = line.trim()

            if (value === "[font.normal]") {
                inNormalSection = true
                continue
            }

            if (value.startsWith("[")) {
                inNormalSection = false
            } else if (inNormalSection) {
                const match = value.match(/^family[ \t]*=[ \t]*"([^"]+)"$/)
                if (match) return match[1]
            }
        }

        return ""
    }

    FileView {
        id: ghosttyConfig
        path: root.configHome + "/ghostty/config.ghostty"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: alacrittyConfig
        path: root.configHome + "/alacritty/alacritty.toml"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }
}
