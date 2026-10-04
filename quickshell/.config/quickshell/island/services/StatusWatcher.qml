pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../core"

Item {
    id: root
    readonly property string eventDirectory: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/island/status"
    property var brightnessStamps: ({})

    function volumeIcon(value) {
        return value <= 0 ? "󰝟" : value < 30 ? "󰕿" : value < 50 ? "󰖀" : value < 70 ? "󰕾" : "";
    }

    function showBrightness(parts, value) {
        const source = BrightnessService.getMonitor(parts[2]);
        const monitorName = source?.connector || parts[2] || Hyprland.focusedMonitor?.name || ThemeService.islandScreens[0]?.name || "";
        if (parts[3]) {
            if (brightnessStamps[monitorName] === parts[3]) return;
            brightnessStamps = Object.assign({}, brightnessStamps, {[monitorName]: parts[3]});
        }
        StatusManager.show({mode: "brightness", monitorName: monitorName,
            label: source?.label || monitorName, icon: value < 25 ? "󰃞" : value < 60 ? "󰃟" : "󰃠",
            title: value + "%", value: value});
    }

    function readEvent(data) {
        const parts = data.trim().split("|");
        if (parts.length < 2 || parts.length > 4 || !parts[1]) return;
        const type = parts[0];
        const value = Number(parts[1]);
        if (!Number.isFinite(value) || value < (type === "volume" ? -1 : 0) || value > 100) return;
        if (type === "volume") {
            StatusManager.show({mode: "volume", icon: volumeIcon(value), title: value < 0 ? "Muted" : value + "%", value: value});
        } else if (type === "brightness") {
            showBrightness(parts, value);
        }
    }

    Connections {
        target: NightLightService
        function onEnabledChanged() {
            if (!NightLightService.ready) return;
            StatusManager.show({mode: "nightlight", icon: NightLightService.enabled ? "󰖔" : "󰖙",
                title: "Nightlight " + NightLightService.subtitle, value: NightLightService.enabled, statusWidth: 220});
        }
    }
    FileView {
        id: eventFile
        path: root.eventDirectory + "/event"
        watchChanges: true
        blockAllReads: true
        onFileChanged: {
            reload();
            root.readEvent(text());
            for (const channel of brightnessChannels.instances) channel.reload();
        }
    }
    Variants {
        id: brightnessChannels
        model: Quickshell.screens
        BrightnessOsdEvent {
            directory: root.eventDirectory
            onReceived: event => root.readEvent(event)
        }
    }
}
