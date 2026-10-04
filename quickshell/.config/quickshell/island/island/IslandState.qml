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

    // =========================================================
    // STATE
    // =========================================================

    property int mode: defaultMode
    property string panelMonitorName: ""
    property string settingsSection: ""

    property bool islandPinned: false
    property bool returnToExpanded: false
    property bool ignoreNextIslandTap: false

    // =========================================================
    // DERIVED STATE
    // =========================================================

    readonly property bool modal:
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
        mode === audioDevicesMode
}
