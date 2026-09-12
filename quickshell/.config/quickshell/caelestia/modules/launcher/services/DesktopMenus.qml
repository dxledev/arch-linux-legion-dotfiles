pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

Singleton {
    id: root

    readonly property var menus: ["capture", "screenshot", "emojis", "unicode", "layout"]
    readonly property var captureModes: [
        { id: "region", name: "Region", icon: "select" },
        { id: "window", name: "Window", icon: "window" },
        { id: "monitor", name: "Monitor", icon: "monitor" },
        { id: "active-window", name: "Active Window", icon: "picture_in_picture" },
        { id: "active-monitor", name: "Active Monitor", icon: "desktop_windows" }
    ]
    property var emojis: []
    property var unicode: []
    property var layouts: []

    function reload(menu: string): void {
        if (menu === "layout" && !layoutProcess.running)
            layoutProcess.running = true;
    }

    function parse(text: string): var {
        const parts = text.slice(GlobalConfig.launcher.actionPrefix.length).split(/\s+/);
        const menu = parts.shift();
        let mode = "";
        if (menu === "screenshot" && captureModes.some(item => item.id === parts[0]))
            mode = parts.shift();
        return { menu, mode, search: parts.join(" ").trim().toLowerCase() };
    }

    function submenu(name: string, icon: string, path: string): var {
        return { name, icon, path, desc: "" };
    }

    function rows(context: var): var {
        switch (context.menu) {
        case "capture":
            return [submenu("Screenshot", "screenshot_monitor", "screenshot"),
                { name: "Screenrecord", icon: "videocam", command: ["/usr/bin/bash", Quickshell.shellPath("integration/screenrecord")] },
                { name: "Color", icon: "colorize", command: [`${Quickshell.env("HOME")}/bin/launch-colorpicker`] }];
        case "screenshot":
            if (!context.mode)
                return captureModes.map(item => submenu(item.name, item.icon, `screenshot ${item.id}`));
            return [{ name: "Save + Edit", icon: "edit", target: "edit" },
                { name: "Clipboard Only", icon: "content_paste", target: "clipboard" }].map(item => Object.assign({}, item, {
                    command: ["/usr/bin/bash", Quickshell.shellPath("integration/screenshot"), context.mode, item.target]
                }));
        case "emojis":
            return emojis;
        case "unicode":
            return unicode;
        case "layout":
            return layouts.map(item => ({ name: item.name, icon: "view_quilt", desc: item.current ? "Current layout" : "",
                command: ["/usr/bin/bash", `${Quickshell.env("HOME")}/bin/menu-layout`, "--layout", item.id] }));
        }
        return [];
    }

    function query(text: string): var {
        const context = parse(text);
        const words = context.search.split(/\s+/);
        return rows(context).filter(item => words.every(word => `${item.name} ${item.meta ?? ""} ${item.desc ?? ""} ${item.glyph ?? ""}`.toLowerCase().includes(word))).map(item => Object.assign({}, item, {
            onClicked: list => {
                if (item.path) {
                    list.search.text = `${GlobalConfig.launcher.actionPrefix}${item.path} `;
                } else {
                    list.screenState.launcher = false;
                    const command = item.glyph
                        ? ["/usr/bin/bash", Quickshell.shellPath("integration/characters"), "--copy", item.glyph]
                        : item.command;
                    if (command)
                        Quickshell.execDetached(command);
                }
            }
        }));
    }

    function readRows(output: string, exitCode: int, label: string): var {
        if (exitCode === 0) {
            try {
                return JSON.parse(output);
            } catch (error) {
                console.warn(`Could not parse ${label}:`, error);
            }
        } else {
            console.warn(`Could not load ${label}`);
        }
        return [];
    }

    Process {
        running: true
        command: ["/usr/bin/bash", Quickshell.shellPath("integration/characters"), "--list", "emojis"]
        stdout: StdioCollector {}
        onExited: code => root.emojis = root.readRows(stdout.text, code, "emojis")
    }

    Process {
        running: true
        command: ["/usr/bin/bash", Quickshell.shellPath("integration/characters"), "--list", "unicode"]
        stdout: StdioCollector {}
        onExited: code => root.unicode = root.readRows(stdout.text, code, "unicode")
    }

    Process {
        id: layoutProcess
        command: ["/usr/bin/bash", Quickshell.shellPath("integration/layouts")]
        stdout: StdioCollector {}
        onExited: code => root.layouts = root.readRows(stdout.text, code, "layouts")
    }
}
