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
    width: implicitWidth
    height: implicitHeight

    // Incoming panels fade in as the capsule nears its target size instead of appearing at
    // full opacity inside a half-grown shape. Power and system have their own entrance.
    property real morphCloseness: 1
    property bool morphRunning: false
    property int morphDuration: 300
    property bool revealEnabled: true
    readonly property bool revealGated: revealEnabled && mode !== IslandState.powerMenuMode && mode !== IslandState.systemMode
    // Latched so a relayout inside an open panel (a collapsing section) never dims it again.
    property bool settled: true
    // Held at zero from the mode change until the new target size has been applied.
    property bool revealHeld: false
    property bool revealAnimated: true
    readonly property real revealTarget: revealHeld ? 0 : settled ? 1 : Math.pow(morphCloseness, 1.3)
    property real reveal: revealTarget
    opacity: revealGated ? reveal : 1

    Behavior on reveal {
        enabled: root.revealAnimated
        NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic }
    }

    // Settings sections swap views without changing the mode, so they key the reveal too.
    readonly property string viewKey: mode + ":" + (mode === IslandState.settingsSectionMode ? IslandState.settingsSection : "")
    onViewKeyChanged: {
        // Snap to hidden without animating so the previous panel's opacity never carries over.
        revealAnimated = false
        revealHeld = true
        settled = false
        Qt.callLater(() => {
            root.revealAnimated = true
            root.revealHeld = false
            // Same-size panels never move closeness, so settle them here.
            if (root.morphCloseness > 0.92 && !root.morphRunning)
                root.settled = true
            settleBackstop.restart()
        })
    }
    onMorphClosenessChanged: if (!settled && !revealHeld && morphCloseness > 0.92) settled = true

    // Content can never stay hidden if a morph is interrupted or its target never arrives.
    Timer {
        id: settleBackstop
        interval: Math.round(root.morphDuration * 1.6) + Theme.animationFast
        onTriggered: root.settled = true
    }

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
                case "menu": return menuSettingsView
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

            case IslandState.aiUsageMode:
                return aiUsageView

            case IslandState.controlCenterMode:
                return null

            case IslandState.notificationsMode:
                return notificationsView

            case IslandState.audioDevicesMode:
                return audioDevicesView

            case IslandState.wifiMode:
                return wifiView

            case IslandState.bluetoothMode:
                return bluetoothView

            case IslandState.clipboardMode:
                return clipboardView

            case IslandState.chromackMode:
                return chromackView

            case IslandState.wallhavenMode:
                return wallhavenView

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
    Component { id: aiUsageView; AIUsageView {} }
    Component { id: launcherSettingsView; LauncherSettingsView {} }
    Component { id: menuSettingsView; MenuSettingsView {} }
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
    Component { id: wifiView; WifiView {} }
    Component { id: bluetoothView; BluetoothView {} }
    Component { id: clipboardView; ClipboardView {} }
    Component { id: chromackView; ChromackView {} }
    Component { id: wallhavenView; WallhavenView {} }

    Component {
        id: defaultView
        CompactView { monitorActive: root.monitorActive; monitorName: root.monitorName }
    }

    Component {
        id: expandedView
        ExpandedView { monitorName: root.monitorName }
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
