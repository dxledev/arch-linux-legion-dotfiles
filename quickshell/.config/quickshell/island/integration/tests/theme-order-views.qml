import QtQuick
import Quickshell
import Quickshell.Io
import "services"
import "styles"

ShellRoot {
    id: root
    readonly property bool ready: ThemeService.ready
    property bool colorsMatch: false
    Process {
        id: paletteReader
        command: [ThemeService.controller, "ui"]
        stdout: StdioCollector {}
        onExited: function(code) {
            if (code !== 0) return;
            const colors = JSON.parse(stdout.text).colors;
            root.colorsMatch = Qt.colorEqual(Theme.background, colors.background) && Qt.colorEqual(Theme.accent, colors.primary);
        }
    }
    IpcHandler {
        target: "themeOrder"
        function snapshot(): string {
            if (!paletteReader.running) paletteReader.running = true;
            return JSON.stringify({ready: ThemeService.ready, source: ThemeService.state.source,
                mode: ThemeService.state.mode, variant: ThemeService.state.variant,
                wallpaper: ThemeService.wallpaper, colorsMatch: root.colorsMatch});
        }
        function quit(): void { Qt.quit(); }
    }
}
