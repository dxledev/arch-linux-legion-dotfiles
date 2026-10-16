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
    readonly property int calendarMode: 23
    readonly property int layoutSwitcherMode: 24
    readonly property int workspaceAxisMode: 25
    readonly property int keybindsMode: 26
    readonly property int forecastMode: 27
    readonly property int powerProfileMode: 28
    readonly property int protonVpnMode: 29
    readonly property int libreOfficeMode: 30

    // =========================================================
    // STATE
    // =========================================================

    property int mode: defaultMode
    property int systemReturnMode: navigationMode
    property int calendarReturnMode: navigationMode
    // Day (yyyy-MM-dd) the Calendar and its Forecast panel share. Opening the Forecast stores the
    // calendar's selection; Back reopens the calendar on it and clears it. "" means today.
    property string calendarSelectedKey: ""
    property var calendarQuote: null
    // Height of the calendar's month card, so the Forecast fills the same space. 0 until known.
    property real calendarCardHeight: 0
    property string panelMonitorName: ""
    property string settingsSection: ""

    property bool islandPinned: false
    // Expanded island's workspace section (persistent and special workspaces, overview toggles).
    // Only meaningful while the island is expanded; any other mode closes it.
    property bool workspacePanelOpen: false
    onModeChanged: {
        if (mode !== expandedMode) workspacePanelOpen = false
        if (mode !== calendarMode && mode !== forecastMode) {
            calendarSelectedKey = ""
            calendarQuote = null
            calendarCardHeight = 0
        }
    }
    property bool returnToExpanded: false
    property bool ignoreNextIslandTap: false
    // Media opened from a click: stay open until the cursor has entered the panel once.
    property bool awaitingMediaHover: false
    // Item of an open dropdown list, which can reach past the panel. The window's input mask includes
    // it so clicking an option is not taken for a click outside the panel (which closes it).
    property Item dropdownArea: null

    // Floating lyrics card. Independent of the island mode: only the card's close button clears it.
    property bool lyricsOpen: false
    property string lyricsMonitorName: ""
    // Monitor whose island shows the current lyric line in place of the clock, "" when none.
    // Reached by the lyrics card's icon or the Super+Ctrl+L toggle; any panel opening or a click on the island clears it.
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
        mode === wallhavenMode ||
        mode === calendarMode ||
        mode === layoutSwitcherMode ||
        mode === workspaceAxisMode ||
        mode === keybindsMode ||
        mode === forecastMode ||
        mode === powerProfileMode ||
        mode === protonVpnMode ||
        mode === libreOfficeMode
}
