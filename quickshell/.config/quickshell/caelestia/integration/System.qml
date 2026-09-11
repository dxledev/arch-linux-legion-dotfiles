pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var workspaceStarts: ({})
    property bool hasProfilePicture: false
    property bool syncWindowRounding: true
    property real windowRoundingPower: 2.0
    readonly property string home: Quickshell.env("HOME")
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || home + "/.config"
    readonly property string themeFile: Quickshell.env("SHELL_THEME_FILE") || configHome + "/themes/current/Colors.qml"
    readonly property string wallpaper: Quickshell.env("SHELL_WALLPAPER") || configHome + "/themes/current/wallpaper.png"
    readonly property string profilePicture: Quickshell.env("SHELL_PROFILE_PICTURE") || home + "/.face"
    readonly property string actionScript: Quickshell.shellPath("integration/system-action")

    function run(action: string, args: list<string>): void {
        Quickshell.execDetached([actionScript, action, ...(args || [])]);
    }

    function refreshProfile(): void { profileCheck.running = true; }

    Process {
        id: profileCheck
        command: ["/usr/bin/test", "-f", root.profilePicture]
        running: true
        onExited: code => root.hasProfilePicture = code === 0
    }

    FileView {
        path: root.configHome + "/caelestia/integration.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const config = JSON.parse(text());
            root.workspaceStarts = config.workspaceStarts || {};
            root.syncWindowRounding = config.windowRounding?.enabled ?? true;
            root.windowRoundingPower = config.windowRounding?.power ?? 2.0;
        }
    }
}
