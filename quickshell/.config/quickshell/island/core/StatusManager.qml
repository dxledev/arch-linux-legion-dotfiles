pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../services"
import "../services/MonitorSelection.js" as MonitorSelection

Singleton {
    id: root
    property bool visible: false
    property string mode: ""
    property string monitorName: ""
    property string icon: ""
    property string title: ""
    property var value
    property int statusWidth: 160
    property int statusHeight: 33
    property int animationDuration: 0
    property var brightnessEvent: null
    readonly property var brightnessEvents: brightnessEvent ? [brightnessEvent] : []
    readonly property string targetMonitorName: MonitorSelection.osdMonitorName(monitorName, ThemeService.islandScreens)

    function isTargetScreen(screenName) {
        return screenName === targetMonitorName;
    }

    function brightnessForScreen(screenName) {
        return mode === "brightness" && isTargetScreen(screenName) ? brightnessEvents : [];
    }

    function showBrightness(data) {
        brightnessEvent = {
            monitorName: data.monitorName || "", label: data.label || data.monitorName || "Brightness",
            icon: data.icon, value: data.value
        };
    }

    function show(data) {
        if (data.mode === "brightness") showBrightness(data);
        else brightnessEvent = null;
        mode = data.mode;
        monitorName = data.monitorName || Hyprland.focusedMonitor?.name || ThemeService.islandScreens[0]?.name || "";
        icon = data.icon;
        title = data.title;
        value = data.value;
        statusWidth = data.statusWidth ?? 160;
        statusHeight = data.statusHeight ?? 33;
        animationDuration = data.animationDuration ?? (["volume", "brightness", "nightlight", "keyboard"].includes(mode) ? OsdSettings.animationDuration : 0);
        visible = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: ["volume", "brightness", "nightlight", "keyboard"].includes(root.mode) ? OsdSettings.timeout : 1800
        onTriggered: root.visible = false
    }
}
