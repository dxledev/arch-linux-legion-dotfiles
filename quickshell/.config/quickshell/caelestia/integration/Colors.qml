pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var values: ({})
    readonly property color background: values.background || "#191724"
    readonly property color foreground: values.foreground || "#e0def4"
    readonly property color primary: values.primary || "#9ccfd8"
    readonly property color secondary: values.secondary || primary
    readonly property color surface: values.backgroundGray || "#302d3e"
    readonly property color muted: values.muted || "#908caa"
    readonly property color border: values.border || primary
    readonly property color warning: values.warning || "#f6c177"
    readonly property color danger: values.danger || "#eb6f92"
    readonly property color success: values.success || "#31748f"
    readonly property bool light: background.hslLightness > 0.5

    function reload(): void {
        source.reload();
    }

    function parse(contents: string): void {
        const next = {};
        const expression = /property\s+color\s+(\w+)\s*:\s*["'](#[0-9a-fA-F]{6,8})["']/g;
        let match;
        while ((match = expression.exec(contents)) !== null)
            next[match[1]] = match[2];
        if (next.background && next.foreground && next.primary)
            values = next;
        else
            console.warn("Shared theme is missing background, foreground or primary:", System.themeFile);
    }

    function mix(base: color, tint: color, amount: real): color {
        return Qt.tint(base, Qt.alpha(tint, amount));
    }

    function on(accent: color): color {
        return accent.hslLightness > 0.55 ? background : foreground;
    }

    function palette(): var {
        const result = {
            m3background: background, m3onBackground: foreground,
            m3surface: background, m3surfaceDim: background,
            m3surfaceBright: surface, m3surfaceContainerLowest: background,
            m3surfaceContainerLow: mix(background, foreground, 0.035),
            m3surfaceContainer: mix(background, foreground, 0.055),
            m3surfaceContainerHigh: mix(background, foreground, 0.085),
            m3surfaceContainerHighest: surface, m3surfaceVariant: surface,
            m3onSurface: foreground, m3onSurfaceVariant: muted,
            m3inverseSurface: foreground, m3inverseOnSurface: background,
            m3outline: border, m3outlineVariant: surface,
            m3shadow: "#000000", m3scrim: "#000000", m3surfaceTint: primary,
            m3inversePrimary: primary,
            m3neutral_paletteKeyColor: background, m3neutral_variant_paletteKeyColor: surface
        };
        for (const [name, accent] of Object.entries({primary, secondary, tertiary: warning, error: danger, success})) {
            result["m3" + name] = accent;
            result["m3on" + name[0].toUpperCase() + name.slice(1)] = on(accent);
            result["m3" + name + "Container"] = mix(background, accent, 0.22);
            result["m3on" + name[0].toUpperCase() + name.slice(1) + "Container"] = foreground;
            if (["primary", "secondary", "tertiary"].includes(name)) {
                const capital = name[0].toUpperCase() + name.slice(1);
                result["m3" + name + "_paletteKeyColor"] = accent;
                result["m3" + name + "Fixed"] = accent;
                result["m3" + name + "FixedDim"] = mix(background, accent, 0.8);
                result["m3on" + capital + "Fixed"] = on(accent);
                result["m3on" + capital + "FixedVariant"] = on(accent);
            }
        }
        const terminal = [background, danger, success, warning, primary, secondary, primary, foreground,
                          muted, danger, success, warning, primary, secondary, primary, foreground];
        terminal.forEach((color, index) => result["term" + index] = color);
        return result;
    }

    FileView {
        id: source
        path: System.themeFile
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parse(text())
    }
}
