import QtQuick

import "../views"
import "../core"
import "../services"
import "../styles"

Item {
    id: root

    property int mode: IslandState.mode
    property bool monitorActive: true
    property string monitorName: ""
    readonly property bool showingWallpapers: mode === IslandState.wallpaperSelectorMode
    readonly property bool showingControlCenter: mode === IslandState.controlCenterMode
    readonly property Item currentView: showingWallpapers ? wallpaperLoader.item
        : showingControlCenter ? controlCenterLoader.item : viewLoader.item
    implicitWidth: currentView ? currentView.implicitWidth : 0
    implicitHeight: currentView ? currentView.implicitHeight : 0

    Loader {
        id: wallpaperLoader
        property bool opened: false
        active: opened
        visible: root.showingWallpapers
        enabled: root.showingWallpapers
        anchors.centerIn: parent
        width: item ? item.implicitWidth : 0
        height: item ? item.implicitHeight : 0
        sourceComponent: wallpaperSelectorView
    }
    onShowingWallpapersChanged: if (showingWallpapers) wallpaperLoader.opened = true
    Component.onCompleted: {
        if (showingWallpapers) wallpaperLoader.opened = true
    }

    Loader {
        id: controlCenterLoader
        active: ThemeService.ready
        asynchronous: !root.showingControlCenter
        visible: root.showingControlCenter
        enabled: root.showingControlCenter
        anchors.centerIn: parent
        width: item ? item.implicitWidth : 0
        height: item ? item.implicitHeight : 0
        sourceComponent: controlCenterView
    }

    Loader {
        id: viewLoader

        onLoaded: {
            sessionEntrance.stop()
            opacity = 1
            scale = 1
            if (root.mode === IslandState.powerMenuMode || root.mode === IslandState.systemMode)
                sessionEntrance.restart()
        }

        ParallelAnimation {
            id: sessionEntrance
            NumberAnimation {
                target: viewLoader
                property: "opacity"
                from: 0
                to: 1
                duration: Theme.animationNormal
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: viewLoader
                property: "scale"
                from: 0.94
                to: 1
                duration: Theme.animationNormal
                easing.type: Easing.OutCubic
            }
        }

        anchors.centerIn: parent
        anchors.alignWhenCentered: false

        width: item ? item.implicitWidth : 0
        height: item ? item.implicitHeight : 0

        sourceComponent: {

            switch (root.mode) {

            case IslandState.launcherMode:
                return launcherView

            case IslandState.navigationMode:
                return navigationView

            case IslandState.settingsMode:
                return settingsView

            case IslandState.settingsSectionMode:
                switch (IslandState.settingsSection) {
                case "launcher": return launcherSettingsView
                case "appearance": return appearanceSettingsView
                case "clock": return clockSettingsView
                case "lock": return lockSettingsView
                case "osd": return osdSettingsView
                case "workspaces": return workspacesSettingsView
                case "dynamicPalette": return dynamicPaletteSettingsView
                case "notifications": return notificationsSettingsView
                case "interaction": return interactionSettingsView
                case "wallpaperAnimation": return wallpaperAnimationSettingsView
                default: return settingsView
                }

            case IslandState.clockSettingsMode:
                return clockSettingsView

            case IslandState.osdSettingsMode:
                return osdSettingsView

            case IslandState.shellSwitcherMode:
                return shellSwitcherView

            case IslandState.expandedMode:
                return expandedView

            case IslandState.powerMenuMode:
                return powerMenuView

            case IslandState.systemMode:
                return systemView

            case IslandState.controlCenterMode:
                return null

            case IslandState.notificationsMode:
                return notificationsView

            case IslandState.audioDevicesMode:
                return audioDevicesView

            case IslandState.themeSelectorMode:
                return themeSelectorView

            case IslandState.wallpaperSelectorMode:
                return null

            case IslandState.mediaControlsMode:
                return mediaView

            default:
                return defaultView
            }
        }
    }

    Component { id: launcherView; LauncherView {} }
    Component { id: systemView; SystemView {} }
    Component { id: launcherSettingsView; LauncherSettingsView {} }
    Component { id: navigationView; NavigationView {} }
    Component { id: settingsView; SettingsView {} }
    Component { id: wallpaperAnimationSettingsView; WallpaperAnimationSettingsView {} }
    Component { id: interactionSettingsView; InteractionSettingsView {} }
    Component { id: notificationsSettingsView; NotificationSettingsView {} }
    Component { id: dynamicPaletteSettingsView; DynamicPaletteSettingsView {} }
    Component { id: workspacesSettingsView; WorkspaceSettingsView {} }
    Component { id: appearanceSettingsView; AppearanceSettingsView {} }
    Component { id: clockSettingsView; ClockSettingsView {} }
    Component { id: lockSettingsView; LockSettingsView {} }
    Component { id: osdSettingsView; OsdSettingsView {} }
    Component { id: shellSwitcherView; ShellSwitcherView {} }
    Component { id: notificationsView; NotificationsPanelView {} }
    Component { id: audioDevicesView; AudioDevicesView {} }

    Component {
        id: defaultView
        CompactView { monitorActive: root.monitorActive; monitorName: root.monitorName }
    }

    Component {
        id: expandedView
        ExpandedView { }
    }

    Component {
        id: powerMenuView
        PowerMenuView { }
    }

    Component {
        id: controlCenterView
        ControlCenterView { }
    }

    Component {
        id: themeSelectorView
        ThemeSelectorView { }
    }

    Component {
        id: wallpaperSelectorView
        WallpaperSelectorView { }
    }

    Component {
        id: mediaView
        MediaView { }
    }
}
