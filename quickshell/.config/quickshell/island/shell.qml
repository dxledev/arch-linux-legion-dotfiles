import QtQuick
import Quickshell
import "windows"
import "services"

ShellRoot {
    id: root
    readonly property var lock: LockService
    readonly property bool startupLocked: Quickshell.env("ISLAND_START_LOCKED") === "1"
    property bool contentLoaded: false
    settings.watchFiles: false

    Loader {
        active: root.contentLoaded || !root.startupLocked || LockService.secure
        asynchronous: root.startupLocked
        onLoaded: root.contentLoaded = true
        sourceComponent: Scope {
            readonly property var notifications: NotificationService
            StatusWatcher {}
            readonly property var workspaces: WorkspaceService
            readonly property var displays: DisplayService
            KeyboardService {}
            IslandIPC {}

            Variants {
                model: ThemeService.islandScreens
                IslandWindow {
                    required property ShellScreen modelData
                    screen: modelData
                }
            }
        }
    }
}
