pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Images
import qs.services
import qs.utils
import qs.integration

Singleton {
    id: root

    property bool showPreview
    property string scheme
    property string flavour
    property string source: "system"
    property string provider: "theme"
    property string variant: "tonalspot"
    readonly property bool light: showPreview ? previewLight : currentLight
    property bool currentLight
    property bool previewLight
    readonly property M3Palette palette: showPreview ? preview : current
    readonly property M3TPalette tPalette: M3TPalette {}
    readonly property M3Palette current: M3Palette {}
    readonly property M3Palette preview: M3Palette {}
    readonly property Transparency transparency: Transparency {}
    readonly property alias wallLuminance: analyser.luminance

    property bool cooldownPending
    property real lastBaseTransparency
    property list<string> pendingControllerArgs: []
    property bool aetherSyncQueued

    readonly property string controller: Quickshell.shellPath("integration/shell-theme")

    function getLuminance(c: color): real {
        if (c.r == 0 && c.g == 0 && c.b == 0)
            return 0;
        return Math.sqrt(0.299 * (c.r ** 2) + 0.587 * (c.g ** 2) + 0.114 * (c.b ** 2));
    }

    function alterColour(c: color, a: real, layer: int): color {
        const luminance = getLuminance(c);

        const offset = (!light || layer == 1 ? 1 : -layer / 2) * (light ? 0.2 : 0.3) * (1 - transparency.base) * (1 + wallLuminance * (light ? (layer == 1 ? 3 : 1) : 2.5));
        const scale = (luminance + offset) / luminance;
        const r = Math.max(0, Math.min(1, c.r * scale));
        const g = Math.max(0, Math.min(1, c.g * scale));
        const b = Math.max(0, Math.min(1, c.b * scale));

        return Qt.rgba(r, g, b, a);
    }

    function layer(c: color, layer: var): color {
        if (!transparency.enabled)
            return c;

        return layer === 0 ? Qt.alpha(c, transparency.base) : alterColour(c, transparency.layers, layer ?? 1);
    }

    function on(c: color): color {
        if (c.hslLightness < 0.5)
            return Qt.hsla(c.hslHue, c.hslSaturation, 0.9, 1);
        return Qt.hsla(c.hslHue, c.hslSaturation, 0.1, 1);
    }

    function load(data: string, isPreview: bool): void {
        const colours = isPreview ? preview : current;
        const scheme = JSON.parse(data);

        if (!isPreview) {
            root.source = scheme.source ?? (scheme.name === "dynamic" ? "dynamic" : "system");
            root.provider = scheme.provider ?? (root.source === "dynamic" ? "caelestia" : "theme");
            variant = scheme.variant ?? "tonalspot";
            if (root.source === "system") {
                loadSystemPalette();
                return;
            }
            root.scheme = scheme.name;
            flavour = scheme.flavour;
            currentLight = scheme.mode === "light";
        } else {
            previewLight = scheme.mode === "light";
        }

        for (const [name, colour] of Object.entries(scheme.colours)) {
            const propName = name.startsWith("term") ? name : `m3${name}`;
            if (colours.hasOwnProperty(propName))
                colours[propName] = `#${colour}`;
        }
        if (!isPreview && scheme.provider === "aether")
            loadAetherPalette(scheme.colours);
        if (!isPreview && root.source === "dynamic" && root.provider === "caelestia")
            queueAetherSync();
    }

    function queueAetherSync(): void {
        if (aetherSyncProc.running) {
            aetherSyncQueued = true;
            return;
        }
        aetherSyncProc.running = true;
    }

    function paletteColour(colours: var, name: string, fallback: color): color {
        const value = colours[name];
        return value ? `#${value}` : fallback;
    }

    function loadAetherPalette(colours: var): void {
        const background = paletteColour(colours, "background", current.m3background);
        const foreground = paletteColour(colours, "onBackground", current.m3onBackground);
        const accent = paletteColour(colours, "accent", paletteColour(colours, "blue", current.m3primary));
        const muted = paletteColour(colours, "muted", current.m3onSurfaceVariant);
        const secondary = paletteColour(colours, "cyan", current.m3secondary);
        const tertiary = paletteColour(colours, "yellow", current.m3tertiary);
        const error = paletteColour(colours, "red", current.m3error);
        const success = paletteColour(colours, "green", current.m3success);
        const surface = paletteColour(colours, "term8", muted);

        const values = {
            m3primary_paletteKeyColor: accent,
            m3secondary_paletteKeyColor: secondary,
            m3tertiary_paletteKeyColor: tertiary,
            m3neutral_paletteKeyColor: background,
            m3neutral_variant_paletteKeyColor: surface,
            m3background: background,
            m3onBackground: foreground,
            m3surface: background,
            m3surfaceDim: background,
            m3surfaceBright: surface,
            m3surfaceContainerLowest: background,
            m3surfaceContainerLow: Qt.tint(background, Qt.alpha(foreground, 0.035)),
            m3surfaceContainer: Qt.tint(background, Qt.alpha(foreground, 0.055)),
            m3surfaceContainerHigh: Qt.tint(background, Qt.alpha(foreground, 0.085)),
            m3surfaceContainerHighest: surface,
            m3onSurface: foreground,
            m3surfaceVariant: surface,
            m3onSurfaceVariant: muted,
            m3inverseSurface: foreground,
            m3inverseOnSurface: background,
            m3outline: muted,
            m3outlineVariant: surface,
            m3shadow: "#000000",
            m3scrim: "#000000",
            m3surfaceTint: accent,
            m3primary: accent,
            m3onPrimary: on(accent),
            m3primaryContainer: Qt.tint(background, Qt.alpha(accent, 0.22)),
            m3onPrimaryContainer: foreground,
            m3inversePrimary: accent,
            m3secondary: secondary,
            m3onSecondary: on(secondary),
            m3secondaryContainer: Qt.tint(background, Qt.alpha(secondary, 0.22)),
            m3onSecondaryContainer: foreground,
            m3tertiary: tertiary,
            m3onTertiary: on(tertiary),
            m3tertiaryContainer: Qt.tint(background, Qt.alpha(tertiary, 0.22)),
            m3onTertiaryContainer: foreground,
            m3error: error,
            m3onError: on(error),
            m3errorContainer: Qt.tint(background, Qt.alpha(error, 0.22)),
            m3onErrorContainer: foreground,
            m3success: success,
            m3onSuccess: on(success),
            m3successContainer: Qt.tint(background, Qt.alpha(success, 0.22)),
            m3onSuccessContainer: foreground
        };
        for (const [name, value] of Object.entries(values))
            current[name] = value;
        for (const role of ["primary", "secondary", "tertiary"]) {
            const capital = role[0].toUpperCase() + role.slice(1);
            const value = values[`m3${role}`];
            current[`m3${role}Fixed`] = value;
            current[`m3${role}FixedDim`] = Qt.tint(background, Qt.alpha(value, 0.8));
            current[`m3on${capital}Fixed`] = on(value);
            current[`m3on${capital}FixedVariant`] = on(value);
        }
        for (let index = 0; index < 16; index++)
            current[`term${index}`] = paletteColour(colours, `term${index}`, index < 8 ? background : foreground);
    }

    function aetherPalette(): var {
        const active = palette;
        const terminal = [];
        for (let index = 0; index < 16; index++)
            terminal.push(String(active[`term${index}`]));
        return {
            mode: light ? "light" : "dark",
            background: String(active.m3background),
            foreground: String(active.m3onBackground),
            accent: String(active.m3primary),
            muted: String(active.m3onSurfaceVariant),
            red: String(active.m3error),
            green: String(active.m3success),
            yellow: String(active.m3tertiary),
            blue: String(active.m3primary),
            magenta: String(active.m3secondary),
            cyan: String(active.term6),
            terminal
        };
    }

    function setMode(mode: string): void {
        if (source !== "dynamic")
            return;
        runController(["set-mode", mode]);
    }

    function toggleMode(): void {
        if (source !== "dynamic")
            return;
        runController(["toggle-mode"]);
    }

    function setVariant(name: string): void {
        if (source !== "dynamic")
            return;
        runController(["set-variant", name]);
    }

    function setSource(name: string): void {
        runController(["set-source", name]);
    }

    function refresh(): void {
        runController(["refresh"]);
    }

    function runController(args: list<string>): void {
        if (controllerProc.running) {
            pendingControllerArgs = args;
            return;
        }
        controllerProc.command = [controller, ...args];
        controllerProc.running = true;
    }

    function loadSystemPalette(): void {
        scheme = "system";
        flavour = "";
        source = "system";
        provider = "theme";
        currentLight = Colors.light;
        showPreview = false;
        for (const [name, color] of Object.entries(Colors.palette()))
            current[name] = color;
    }

    function reloadHyprRules(): void {
        let rule, trEnabled;
        if (Hypr.usingLua) {
            rule = `eval hl.layer_rule({ match = { namespace = "caelestia-drawers" }, %1 = %2 })`;
            trEnabled = transparency.enabled;
        } else {
            rule = "keyword layerrule %1 %2, match:namespace caelestia-drawers";
            trEnabled = transparency.enabled ? 1 : 0;
        }
        Hypr.extras.batchMessage([rule.arg("blur").arg(trEnabled), rule.arg("ignore_alpha").arg(Math.max(0, transparency.base - 0.03))]);
    }

    function requestReloadHyprRules(): void {
        if (cooldownTimer.running) {
            root.cooldownPending = true;
        } else {
            root.reloadHyprRules();
            cooldownTimer.restart();
        }
    }

    Component.onCompleted: {
        root.loadSystemPalette();
        root.refresh();
        root.requestReloadHyprRules();
    }

    Connections {
        function onConfigReloaded(): void {
            root.reloadHyprRules();
        }

        target: Hypr
    }

    Connections {
        target: Colors
        function onValuesChanged(): void {
            if (root.source === "system")
                root.loadSystemPalette();
        }
    }

    FileView {
        id: paletteSource
        path: `${Paths.state}/shell-theme-palette.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.load(text(), false)
    }

    Process {
        id: controllerProc

        stderr: StdioCollector {}
        onExited: code => {
            if (code === 0)
                paletteSource.reload();
            else
                console.warn("Shell theme update failed:", stderr.text);

            if (root.pendingControllerArgs.length) {
                const args = root.pendingControllerArgs;
                root.pendingControllerArgs = [];
                Qt.callLater(() => root.runController(args));
            }
        }
    }

    Process {
        id: aetherSyncProc

        command: [Quickshell.shellPath("integration/aether"), "sync"]
        stderr: StdioCollector {}
        onExited: code => {
            if (code !== 0)
                console.warn("Aether palette sync failed:", stderr.text.trim());
            if (root.aetherSyncQueued) {
                root.aetherSyncQueued = false;
                Qt.callLater(root.queueAetherSync);
            }
        }
    }

    ImageAnalyser {
        id: analyser

        source: Wallpapers.current
    }

    Timer {
        id: cooldownTimer

        interval: 30
        onTriggered: {
            if (root.cooldownPending) {
                root.cooldownPending = false;
                root.reloadHyprRules();
                restart();
            }
        }
    }

    Timer {
        id: cAnimCompleteTimer

        interval: Tokens.anim.durations.expressiveSlowEffects
        onTriggered: root.requestReloadHyprRules()
    }

    component Transparency: QtObject {
        readonly property bool enabled: Tokens.transparency.enabled
        readonly property real base: Math.max(0, Math.min(1, Tokens.transparency.base - (root.light ? 0.1 : 0)))
        readonly property real layers: Math.max(0, Math.min(1, Tokens.transparency.layers))

        onEnabledChanged: {
            if (enabled)
                root.requestReloadHyprRules();
            else
                cAnimCompleteTimer.start();
        }
        onBaseChanged: {
            if (root.lastBaseTransparency > base)
                root.requestReloadHyprRules();
            else
                cAnimCompleteTimer.start();
            root.lastBaseTransparency = base;
        }
    }

    component M3TPalette: QtObject {
        readonly property color m3primary_paletteKeyColor: root.layer(root.palette.m3primary_paletteKeyColor)
        readonly property color m3secondary_paletteKeyColor: root.layer(root.palette.m3secondary_paletteKeyColor)
        readonly property color m3tertiary_paletteKeyColor: root.layer(root.palette.m3tertiary_paletteKeyColor)
        readonly property color m3neutral_paletteKeyColor: root.layer(root.palette.m3neutral_paletteKeyColor)
        readonly property color m3neutral_variant_paletteKeyColor: root.layer(root.palette.m3neutral_variant_paletteKeyColor)
        readonly property color m3background: root.layer(root.palette.m3background, 0)
        readonly property color m3onBackground: root.layer(root.palette.m3onBackground)
        readonly property color m3surface: root.layer(root.palette.m3surface, 0)
        readonly property color m3surfaceDim: root.layer(root.palette.m3surfaceDim, 0)
        readonly property color m3surfaceBright: root.layer(root.palette.m3surfaceBright, 0)
        readonly property color m3surfaceContainerLowest: root.layer(root.palette.m3surfaceContainerLowest)
        readonly property color m3surfaceContainerLow: root.layer(root.palette.m3surfaceContainerLow)
        readonly property color m3surfaceContainer: root.layer(root.palette.m3surfaceContainer)
        readonly property color m3surfaceContainerHigh: root.layer(root.palette.m3surfaceContainerHigh)
        readonly property color m3surfaceContainerHighest: root.layer(root.palette.m3surfaceContainerHighest)
        readonly property color m3onSurface: root.layer(root.palette.m3onSurface)
        readonly property color m3surfaceVariant: root.layer(root.palette.m3surfaceVariant, 0)
        readonly property color m3onSurfaceVariant: root.layer(root.palette.m3onSurfaceVariant)
        readonly property color m3inverseSurface: root.layer(root.palette.m3inverseSurface, 0)
        readonly property color m3inverseOnSurface: root.layer(root.palette.m3inverseOnSurface)
        readonly property color m3outline: root.layer(root.palette.m3outline)
        readonly property color m3outlineVariant: root.layer(root.palette.m3outlineVariant)
        readonly property color m3shadow: root.layer(root.palette.m3shadow)
        readonly property color m3scrim: root.layer(root.palette.m3scrim)
        readonly property color m3surfaceTint: root.layer(root.palette.m3surfaceTint)
        readonly property color m3primary: root.layer(root.palette.m3primary)
        readonly property color m3onPrimary: root.layer(root.palette.m3onPrimary)
        readonly property color m3primaryContainer: root.layer(root.palette.m3primaryContainer)
        readonly property color m3onPrimaryContainer: root.layer(root.palette.m3onPrimaryContainer)
        readonly property color m3inversePrimary: root.layer(root.palette.m3inversePrimary)
        readonly property color m3secondary: root.layer(root.palette.m3secondary)
        readonly property color m3onSecondary: root.layer(root.palette.m3onSecondary)
        readonly property color m3secondaryContainer: root.layer(root.palette.m3secondaryContainer)
        readonly property color m3onSecondaryContainer: root.layer(root.palette.m3onSecondaryContainer)
        readonly property color m3tertiary: root.layer(root.palette.m3tertiary)
        readonly property color m3onTertiary: root.layer(root.palette.m3onTertiary)
        readonly property color m3tertiaryContainer: root.layer(root.palette.m3tertiaryContainer)
        readonly property color m3onTertiaryContainer: root.layer(root.palette.m3onTertiaryContainer)
        readonly property color m3error: root.layer(root.palette.m3error)
        readonly property color m3onError: root.layer(root.palette.m3onError)
        readonly property color m3errorContainer: root.layer(root.palette.m3errorContainer)
        readonly property color m3onErrorContainer: root.layer(root.palette.m3onErrorContainer)
        readonly property color m3success: root.layer(root.palette.m3success)
        readonly property color m3onSuccess: root.layer(root.palette.m3onSuccess)
        readonly property color m3successContainer: root.layer(root.palette.m3successContainer)
        readonly property color m3onSuccessContainer: root.layer(root.palette.m3onSuccessContainer)
        readonly property color m3primaryFixed: root.layer(root.palette.m3primaryFixed)
        readonly property color m3primaryFixedDim: root.layer(root.palette.m3primaryFixedDim)
        readonly property color m3onPrimaryFixed: root.layer(root.palette.m3onPrimaryFixed)
        readonly property color m3onPrimaryFixedVariant: root.layer(root.palette.m3onPrimaryFixedVariant)
        readonly property color m3secondaryFixed: root.layer(root.palette.m3secondaryFixed)
        readonly property color m3secondaryFixedDim: root.layer(root.palette.m3secondaryFixedDim)
        readonly property color m3onSecondaryFixed: root.layer(root.palette.m3onSecondaryFixed)
        readonly property color m3onSecondaryFixedVariant: root.layer(root.palette.m3onSecondaryFixedVariant)
        readonly property color m3tertiaryFixed: root.layer(root.palette.m3tertiaryFixed)
        readonly property color m3tertiaryFixedDim: root.layer(root.palette.m3tertiaryFixedDim)
        readonly property color m3onTertiaryFixed: root.layer(root.palette.m3onTertiaryFixed)
        readonly property color m3onTertiaryFixedVariant: root.layer(root.palette.m3onTertiaryFixedVariant)
    }

    component M3Palette: QtObject {
        property color m3primary_paletteKeyColor: "#a8627b"
        property color m3secondary_paletteKeyColor: "#8e6f78"
        property color m3tertiary_paletteKeyColor: "#986e4c"
        property color m3neutral_paletteKeyColor: "#807477"
        property color m3neutral_variant_paletteKeyColor: "#837377"
        property color m3background: "#191114"
        property color m3onBackground: "#efdfe2"
        property color m3surface: "#191114"
        property color m3surfaceDim: "#191114"
        property color m3surfaceBright: "#403739"
        property color m3surfaceContainerLowest: "#130c0e"
        property color m3surfaceContainerLow: "#22191c"
        property color m3surfaceContainer: "#261d20"
        property color m3surfaceContainerHigh: "#31282a"
        property color m3surfaceContainerHighest: "#3c3235"
        property color m3onSurface: "#efdfe2"
        property color m3surfaceVariant: "#514347"
        property color m3onSurfaceVariant: "#d5c2c6"
        property color m3inverseSurface: "#efdfe2"
        property color m3inverseOnSurface: "#372e30"
        property color m3outline: "#9e8c91"
        property color m3outlineVariant: "#514347"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: "#ffb0ca"
        property color m3primary: "#ffb0ca"
        property color m3onPrimary: "#541d34"
        property color m3primaryContainer: "#6f334a"
        property color m3onPrimaryContainer: "#ffd9e3"
        property color m3inversePrimary: "#8b4a62"
        property color m3secondary: "#e2bdc7"
        property color m3onSecondary: "#422932"
        property color m3secondaryContainer: "#5a3f48"
        property color m3onSecondaryContainer: "#ffd9e3"
        property color m3tertiary: "#f0bc95"
        property color m3onTertiary: "#48290c"
        property color m3tertiaryContainer: "#b58763"
        property color m3onTertiaryContainer: "#000000"
        property color m3error: "#ffb4ab"
        property color m3onError: "#690005"
        property color m3errorContainer: "#93000a"
        property color m3onErrorContainer: "#ffdad6"
        property color m3success: "#B5CCBA"
        property color m3onSuccess: "#213528"
        property color m3successContainer: "#374B3E"
        property color m3onSuccessContainer: "#D1E9D6"
        property color m3primaryFixed: "#ffd9e3"
        property color m3primaryFixedDim: "#ffb0ca"
        property color m3onPrimaryFixed: "#39071f"
        property color m3onPrimaryFixedVariant: "#6f334a"
        property color m3secondaryFixed: "#ffd9e3"
        property color m3secondaryFixedDim: "#e2bdc7"
        property color m3onSecondaryFixed: "#2b151d"
        property color m3onSecondaryFixedVariant: "#5a3f48"
        property color m3tertiaryFixed: "#ffdcc3"
        property color m3tertiaryFixedDim: "#f0bc95"
        property color m3onTertiaryFixed: "#2f1500"
        property color m3onTertiaryFixedVariant: "#623f21"
        property color term0: "#353434"
        property color term1: "#ff4c8a"
        property color term2: "#ffbbb7"
        property color term3: "#ffdedf"
        property color term4: "#b3a2d5"
        property color term5: "#e98fb0"
        property color term6: "#ffba93"
        property color term7: "#eed1d2"
        property color term8: "#b39e9e"
        property color term9: "#ff80a3"
        property color term10: "#ffd3d0"
        property color term11: "#fff1f0"
        property color term12: "#dcbc93"
        property color term13: "#f9a8c2"
        property color term14: "#ffd1c0"
        property color term15: "#ffffff"
    }
}
