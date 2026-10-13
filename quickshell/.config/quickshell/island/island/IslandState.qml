pragma Singleton

import QtQuick

QtObject {

    // =========================================================
    // MODES
    // =========================================================

    readonly property int defaultMode: 0
    readonly property int expandedMode: 1
    readonly property int powerMenuMode: 2
    readonly property int controlCenterMode: 3
    readonly property int themeSelectorMode: 4
    readonly property int wallpaperSelectorMode: 5
    readonly property int mediaControlsMode: 6
    readonly property int settingsMode: 7
    readonly property int shellSwitcherMode: 8
    readonly property int navigationMode: 9
    readonly property int notificationsMode: 10
    readonly property int audioDevicesMode: 11
    readonly property int clockSettingsMode: 12
    readonly property int osdSettingsMode: 13
    readonly property int settingsSectionMode: 14
    readonly property int launcherMode: 15
    readonly property int systemMode: 16
    readonly property int aiUsageMode: 17
    readonly property int wifiMode: 18
    readonly property int bluetoothMode: 19
    readonly property int clipboardMode: 20
    readonly property int chromackMode: 21
    readonly property int wallhavenMode: 22

    // =========================================================
    // STATE
    // =========================================================

    property int mode: defaultMode
    property int systemReturnMode: navigationMode
    property string panelMonitorName: ""
    property string settingsSection: ""

    property bool islandPinned: false
    property bool returnToExpanded: false
    property bool ignoreNextIslandTap: false
    // Media opened from a click: stay open until the cursor has entered the panel once.
    property bool awaitingMediaHover: false

    // Floating lyrics card. Independent of the island mode: only the card's close button clears it.
    property bool lyricsOpen: false
    property string lyricsMonitorName: ""
    // Monitor whose island shows the current lyric line in place of the clock, "" when none.
    // Reached only by clicking the lyrics card's icon; any panel opening or a click on the island clears it.
    property string lyricsClockMonitor: ""
    // Per monitor: height of the notification stack currently shown, 0 when none.
    property var notificationExtents: ({})

    function setNotificationExtent(monitorName, extent) {
        if ((notificationExtents[monitorName] ?? 0) === extent)
            return
        const next = Object.assign({}, notificationExtents)
        next[monitorName] = extent
        notificationExtents = next
    }

    property bool lyricsExpanded: false
    readonly property real lyricsBaseHeight: 252
    readonly property real lyricsCardHeight: lyricsExpanded ? lyricsBaseHeight * 2 : lyricsBaseHeight

    // =========================================================
    // DERIVED STATE
    // =========================================================

    readonly property bool modal:
        mode === aiUsageMode ||
        mode === systemMode ||
        mode === launcherMode ||
        mode === navigationMode ||
        mode === settingsMode ||
        mode === settingsSectionMode ||
        mode === clockSettingsMode ||
        mode === osdSettingsMode ||
        mode === shellSwitcherMode ||
        mode === powerMenuMode ||
        mode === themeSelectorMode ||
        mode === wallpaperSelectorMode ||
        mode === notificationsMode ||
        mode === audioDevicesMode ||
        mode === wifiMode ||
        mode === bluetoothMode ||
        mode === clipboardMode ||
        mode === chromackMode ||
        mode === wallhavenMode
}
