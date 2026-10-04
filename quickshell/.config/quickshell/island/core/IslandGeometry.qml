pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../services"

Singleton {
    id: root
    readonly property int compactHeight: Math.max(33, (ThemeService.settings.clockFontSize ?? 18) + 12)
    readonly property int topMargin: ThemeService.settings.topMargin ?? 10
    readonly property int spaceBelow: ThemeService.settings.reservedSpaceBelow ?? 0
    property int windowGapTop: 0
    readonly property int reservedHeight: Math.max(1, topMargin + compactHeight + spaceBelow - windowGapTop)

    Process {
        id: windowGaps
        command: ["/usr/bin/hyprctl", "-j", "getoption", "general:gaps_out"]
        running: !!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: function(code) {
            if (code !== 0) return;
            try {
                const gap = Number(JSON.parse(stdout.text).css.trim().split(/\s+/)[0]);
                if (Number.isFinite(gap)) root.windowGapTop = Math.max(0, Math.round(gap));
            } catch (error) {}
        }
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") windowGaps.running = true;
        }
    }
}
