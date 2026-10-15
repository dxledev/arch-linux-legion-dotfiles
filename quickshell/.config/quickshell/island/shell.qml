import QtQuick
import Quickshell
import "windows"
import "modules/speedtest"
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
            SpeedTest {}
            WindowRounding {
                radius: ThemeService.settings.screenCorners ? ThemeService.settings.screenCornerRadius ?? 24 : -1
            }

            Variants {
                model: Quickshell.screens
                ScreenCornersWindow {
                    required property ShellScreen modelData
                    screen: modelData
                }
            }

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
