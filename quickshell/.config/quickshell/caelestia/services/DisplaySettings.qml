pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var settings: ({})
    property bool ready: false
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"
    readonly property string profileDirectory: Quickshell.env("HYPRMONCFG_CONFIG_DIR") || configHome + "/hyprmoncfg"
    readonly property string settingsPath: profileDirectory + "/display-settings.json"

    function nickname(connector: string): string {
        const value = settings.nicknames?.[connector];
        return typeof value === "string" ? value.trim() : "";
    }

    function nameFor(connector: string): string {
        return nickname(connector) || connector;
    }

    function layoutFor(count: int): string {
        const value = settings.osdLayouts?.[String(count)];
        return ["local", "combined"].includes(value) ? value : count === 2 ? "combined" : "local";
    }

    function setNickname(connector: string, value: string): bool {
        if (!ready || !connector || connector.includes("\n"))
            return false;
        const nicknames = Object.assign({}, settings.nicknames || {});
        const name = value.trim().slice(0, 64);
        if (name)
            nicknames[connector] = name;
        else
            delete nicknames[connector];
        return save({ nicknames });
    }

    function setLayout(count: int, value: string): bool {
        if (!ready || count < 1 || count > 3 || !["local", "combined"].includes(value))
            return false;
        const osdLayouts = Object.assign({}, settings.osdLayouts || {});
        osdLayouts[String(count)] = value;
        return save({ osdLayouts });
    }

    function save(changes: var): bool {
        settings = Object.assign({}, settings, changes);
        storage.setText(JSON.stringify(settings, null, 2) + "\n");
        return true;
    }

    FileView {
        id: storage

        path: root.settingsPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (!data || typeof data !== "object" || Array.isArray(data))
                    throw new Error("Expected display settings object");
                root.settings = data;
                root.ready = true;
            } catch (error) {
                console.warn("Unable to load display settings:", error);
                root.ready = false;
            }
        }
        onLoadFailed: error => root.ready = error === FileViewError.FileNotFound
        onSaveFailed: error => console.warn("Unable to save display settings:", error)
    }

    IpcHandler {
        target: "monitors"

        function name(connector: string): string { return root.nameFor(connector); }
        function setNickname(connector: string, value: string): bool { return root.setNickname(connector, value); }
        function layout(count: int): string { return root.layoutFor(count); }
        function setLayout(count: int, value: string): bool { return root.setLayout(count, value); }
    }
}
