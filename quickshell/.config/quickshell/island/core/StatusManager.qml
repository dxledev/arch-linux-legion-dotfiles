pragma Singleton
import QtQuick
import Quickshell
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
    // A pending yes/no question shown in the drawer; it stays open until answered and ignores other events.
    property bool confirming: false
    property string confirmMonitorName: ""
    property string confirmIcon: ""
    property string confirmTitle: ""
    property int confirmWidth: 380
    property string confirmDetail: ""
    property string confirmAcceptLabel: "Confirm"
    property var confirmHandler: null
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

    function confirm(data) {
        confirmMonitorName = data.monitorName || Compositor.focusedMonitorName || ThemeService.islandScreens[0]?.name || "";
        confirmIcon = data.icon ?? "";
        confirmTitle = data.title;
        confirmDetail = data.detail ?? "";
        confirmAcceptLabel = data.acceptLabel ?? "Confirm";
        confirmHandler = data.onAccepted ?? null;
        confirmWidth = data.statusWidth ?? 380;
        confirming = true;
        showConfirm();
    }

    function showConfirm() {
        mode = "confirm";
        monitorName = confirmMonitorName;
        icon = confirmIcon;
        title = confirmTitle;
        statusWidth = confirmWidth;
        animationDuration = OsdSettings.animationDuration;
        brightnessEvent = null;
        visible = true;
        hideTimer.stop();
    }

    function resolveConfirm(accepted) {
        if (!confirming) return;
        const handler = confirmHandler;
        confirming = false;
        confirmHandler = null;
        hideTimer.stop();
        visible = false;
        if (accepted && handler) handler();
    }

    // While a question is open, other OSDs (volume, brightness...) replace it briefly, then it returns.
    function show(data) {
        if (data.mode === "brightness") showBrightness(data);
        else brightnessEvent = null;
        mode = data.mode;
        monitorName = data.monitorName || Compositor.focusedMonitorName || ThemeService.islandScreens[0]?.name || "";
        icon = data.icon;
        title = data.title;
        value = data.value;
        statusWidth = data.statusWidth ?? 160;
        statusHeight = data.statusHeight ?? 33;
        animationDuration = data.animationDuration ?? (["volume", "brightness", "nightlight", "keyboard", "notice"].includes(mode) ? OsdSettings.animationDuration : 0);
        visible = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: ["volume", "brightness", "nightlight", "keyboard", "notice"].includes(root.mode) ? OsdSettings.timeout : 1800
        onTriggered: {
            if (root.confirming) root.showConfirm();
            else root.visible = false;
        }
    }
}
