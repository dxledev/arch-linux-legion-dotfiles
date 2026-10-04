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
    property var brightnessEvents: []

    function brightnessForScreen(screenName) {
        return MonitorSelection.brightnessForScreen(brightnessEvents, screenName, ThemeService.islandScreens);
    }

    function showBrightness(data) {
        const now = Date.now();
        const retained = mode === "brightness" && visible
            ? brightnessEvents.filter(event => event.monitorName !== data.monitorName && event.expiresAt > now) : [];
        brightnessEvents = [...retained, {
            monitorName: data.monitorName || "", label: data.label || data.monitorName || "Brightness",
            icon: data.icon, value: data.value, expiresAt: now + OsdSettings.timeout
        }].sort((left, right) => left.monitorName.localeCompare(right.monitorName));
    }

    function show(data) {
        if (data.mode === "brightness") showBrightness(data);
        mode = data.mode;
        monitorName = data.monitorName ?? "";
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
    Timer {
        interval: 50
        running: root.visible && root.mode === "brightness"
        repeat: true
        onTriggered: {
            const remaining = root.brightnessEvents.filter(event => event.expiresAt > Date.now());
            if (remaining.length !== root.brightnessEvents.length) root.brightnessEvents = remaining;
            if (!remaining.length) root.visible = false;
        }
    }
}
