import Quickshell
import "windows"
import "services"

ShellRoot {
    readonly property var notifications: NotificationService
    StatusWatcher {}
    readonly property var workspaces: WorkspaceService
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
