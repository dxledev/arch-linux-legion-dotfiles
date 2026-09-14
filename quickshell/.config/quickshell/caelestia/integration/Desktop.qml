import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.services

Scope {
    function syncFont(): void {
        const font = GlobalConfig.appearance.font;
        for (const name of ["headline", "title", "body", "label", "mono"])
            font[name].family = Typography.family;
        font.clock = Typography.family;
        font.workspaces = Typography.family;
    }

    Component.onCompleted: syncFont()

    WindowRounding {
        innerRadius: GlobalConfig.border.rounding
        roundingPower: System.windowRoundingPower
        syncEnabled: System.syncWindowRounding
    }

    Connections {
        target: Typography
        function onFamilyChanged(): void { syncFont(); }
    }

    FontLoader {
        source: Quickshell.shellPath("assets/MaterialSymbolsRounded.ttf")
    }

    IpcHandler {
        target: "theme"
        function reloadColors(): void {
            Colors.reload();
            Colours.setSource("system");
            NotificationFormat.reload();
            Wallpapers.refresh();
        }
        function palette(): string {
            return JSON.stringify(Colors.values);
        }
        function aetherPalette(): string {
            return JSON.stringify(Colours.aetherPalette());
        }
    }

    IpcHandler {
        target: "integration"
        function status(): string {
            return JSON.stringify({
                theme: System.themeFile,
                font: Typography.family,
                wallpaper: Wallpapers.actualCurrent,
                primary: String(Colours.palette.m3primary),
                background: String(Colours.palette.m3background),
                scheme: Colours.scheme,
                source: Colours.source,
                mode: Colours.light ? "light" : "dark",
                variant: Colours.variant,
                workspaceStarts: System.workspaceStarts,
                windowRadius: GlobalConfig.border.rounding,
                roundingPower: System.windowRoundingPower
            });
        }
    }
}
