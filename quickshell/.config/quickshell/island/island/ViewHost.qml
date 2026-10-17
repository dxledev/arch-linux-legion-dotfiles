import QtQuick

import "../views"
import "../core"
import "../services"
import "../services/FocusNavigation.js" as FocusNavigation
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
        Qt.callLater(root.claimFocus)
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

    // Panels that own the keyboard take focus when they open, so keys reach them even if the panel
    // never asked for focus itself.
    function claimFocus() {
        const view = root.currentView
        if (!view || root.mode === IslandState.defaultMode || !IslandState.keyboardPanel
                || root.monitorName !== IslandState.panelMonitorName)
            return
        for (let item = Window.window?.activeFocusItem; item; item = item.parent) {
            if (item === view) return
        }
        view.forceActiveFocus()
    }
    onCurrentViewChanged: Qt.callLater(root.claimFocus)
    // A setting that saves disables its control for a moment, which drops its focus; give it back afterwards.
    property Item lastFocus: null
    Connections {
        target: root.lastFocus
        function onEnabledChanged() {
            const focused = root.Window.window?.activeFocusItem
            const nothing = !focused || focused === root.currentView
            if (root.lastFocus?.enabled && root.lastFocus.visible && nothing && IslandState.keyboardPanel)
                root.lastFocus.forceActiveFocus()
        }
    }
    // Tab, the arrows and Shift+Tab can all land on a control outside the scrolled view.
    Connections {
        target: root.Window.window
        function onActiveFocusItemChanged() {
            const item = root.Window.window?.activeFocusItem
            if (item && item !== root.currentView) root.lastFocus = item
            for (let ancestor = item; ancestor && root.currentView; ancestor = ancestor.parent) {
                if (ancestor !== root.currentView) continue
                FocusNavigation.scrollIntoView(item)
                break
            }
        }
    }
    Connections {
        target: IslandState
        function onKeyboardPanelChanged() { Qt.callLater(root.claimFocus) }
    }

    // Shift+Tab climbs one level, the way the panel's Back button does. A Shortcut, because a focused control
    // would otherwise take the key for its own focus traversal before any handler saw it.
    Shortcut {
        sequences: ["Shift+Tab"]
        enabled: root.monitorActive && root.mode !== IslandState.defaultMode && IslandState.keyboardPanel
            && root.monitorName === IslandState.panelMonitorName
        onActivated: IslandController.goBack()
    }

    // What no panel claimed: Escape closes it and the arrows walk the panel's focusable controls.
    Keys.onPressed: event => {
        if (!IslandState.keyboardPanel || root.mode === IslandState.defaultMode || !root.currentView) return
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) return
        const focused = Window.window?.activeFocusItem
        // A setting that is saving has dropped its focus; keys wait for it instead of jumping elsewhere.
        if (ThemeService.busy && root.lastFocus && !root.lastFocus.enabled && (!focused || focused === root.currentView)) {
            event.accepted = event.key === Qt.Key_Up || event.key === Qt.Key_Down
                || event.key === Qt.Key_Left || event.key === Qt.Key_Right
            if (event.accepted) return
        }
        // A text field keeps Left and Right for its cursor, even at either end of the text.
        if (focused?.cursorPosition !== undefined && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) return
        switch (event.key) {
        case Qt.Key_Escape:
            IslandController.reset()
            event.accepted = true
            break
        case Qt.Key_Up:
            event.accepted = FocusNavigation.move(root.currentView, focused, 0, -1)
            break
        case Qt.Key_Down:
            event.accepted = FocusNavigation.move(root.currentView, focused, 0, 1)
            break
        case Qt.Key_Left:
            event.accepted = FocusNavigation.move(root.currentView, focused, -1, 0)
            break
        case Qt.Key_Right:
            event.accepted = FocusNavigation.move(root.currentView, focused, 1, 0)
            break
        }
    }

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
                case "desktop": return desktopSettingsView
                case "clock": return clockSettingsView
                case "lock": return lockSettingsView
                case "osd": return osdSettingsView
                case "workspaces": return workspacesSettingsView
                case "dynamicPalette": return dynamicPaletteSettingsView
                case "notifications": return notificationsSettingsView
                case "interaction": return interactionSettingsView
                case "wallpaperAnimation": return wallpaperAnimationSettingsView
                case "media": return mediaSettingsView
                case "screenRecording": return screenRecordingSettingsView
                default: return settingsView
                }

            case IslandState.clockSettingsMode:
                return clockSettingsView

            case IslandState.osdSettingsMode:
                return osdSettingsView

            case IslandState.shellSwitcherMode:
                return shellSwitcherView

            case IslandState.layoutSwitcherMode:
                return layoutSwitcherView

            case IslandState.workspaceAxisMode:
                return workspaceAxisView

            case IslandState.expandedMode:
                return expandedView

            case IslandState.powerMenuMode:
                return powerMenuView

            case IslandState.systemMode:
                return systemView

            case IslandState.aiUsageMode:
                return aiUsageView

            case IslandState.keybindsMode:
                return keybindsView

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

            case IslandState.powerProfileMode:
                return powerProfileView

            case IslandState.protonVpnMode:
                return protonVpnView

            case IslandState.libreOfficeMode:
                return libreOfficeView

            case IslandState.recordOptionsMode:
                return recordOptionsView

            case IslandState.timerMode:
                return timerView

            case IslandState.clipboardMode:
                return clipboardView

            case IslandState.chromackMode:
                return chromackView

            case IslandState.wallhavenMode:
                return wallhavenView

            case IslandState.calendarMode:
                return calendarView

            case IslandState.forecastMode:
                return forecastView

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
    Component { id: keybindsView; KeybindsView {} }
    Component { id: launcherSettingsView; LauncherSettingsView {} }
    Component { id: menuSettingsView; MenuSettingsView {} }
    Component { id: navigationView; NavigationView {} }
    Component { id: settingsView; SettingsView {} }
    Component { id: wallpaperAnimationSettingsView; WallpaperAnimationSettingsView {} }
    Component { id: mediaSettingsView; MediaSettingsView {} }
    Component { id: screenRecordingSettingsView; ScreenRecordingSettingsView {} }
    Component { id: recordOptionsView; RecordOptionsView {} }
    Component { id: timerView; TimerView {} }
    Component { id: interactionSettingsView; InteractionSettingsView {} }
    Component { id: notificationsSettingsView; NotificationSettingsView {} }
    Component { id: dynamicPaletteSettingsView; DynamicPaletteSettingsView {} }
    Component { id: workspacesSettingsView; WorkspaceSettingsView {} }
    Component { id: appearanceSettingsView; AppearanceSettingsView {} }
    Component { id: desktopSettingsView; DesktopSettingsView {} }
    Component { id: clockSettingsView; ClockSettingsView {} }
    Component { id: lockSettingsView; LockSettingsView {} }
    Component { id: osdSettingsView; OsdSettingsView {} }
    Component { id: shellSwitcherView; ShellSwitcherView {} }
    Component { id: layoutSwitcherView; LayoutSwitcherView {} }
    Component { id: workspaceAxisView; WorkspaceAxisView {} }
    Component { id: notificationsView; NotificationsPanelView {} }
    Component { id: audioDevicesView; AudioDevicesView {} }
    Component { id: wifiView; WifiView {} }
    Component { id: bluetoothView; BluetoothView {} }
    Component { id: powerProfileView; PowerProfileView {} }
    Component { id: protonVpnView; ProtonVpnView {} }
    Component { id: libreOfficeView; LibreOfficeView {} }
    Component { id: clipboardView; ClipboardView {} }
    Component { id: chromackView; ChromackView {} }
    Component { id: wallhavenView; WallhavenView {} }
    Component { id: calendarView; CalendarView {} }
    Component { id: forecastView; ForecastView {} }

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
