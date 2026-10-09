pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services as Services
import qs.integration as Integration
import "qml/ColourContrast.js" as Contrast

Scope {
    id: root

    property int staticRevision

    function paletteSummary(palette: var): var {
        const surface = Qt.alpha(palette.m3surface, 1);
        const background = Contrast.composite(palette.m3background, surface);
        const colours = {};
        for (const role of ["background", "onBackground", "surface", "surfaceDim", "surfaceBright", "surfaceContainerLowest", "surfaceContainerLow", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest", "onSurface", "surfaceVariant", "onSurfaceVariant", "inverseSurface", "inverseOnSurface", "primary", "onPrimary", "primaryContainer", "onPrimaryContainer", "primaryFixed", "primaryFixedDim", "primary_paletteKeyColor", "secondary", "onSecondary", "secondaryContainer", "onSecondaryContainer", "secondaryFixed", "secondaryFixedDim", "secondary_paletteKeyColor", "tertiary", "onTertiary", "tertiaryContainer", "onTertiaryContainer", "tertiaryFixed", "tertiaryFixedDim", "tertiary_paletteKeyColor", "error", "onError", "errorContainer", "onErrorContainer", "success", "onSuccess", "successContainer", "onSuccessContainer", "inversePrimary", "outline", "outlineVariant", "shadow", "scrim", "surfaceTint", "neutral_paletteKeyColor", "neutral_variant_paletteKeyColor"]) {
            colours[role] = String(palette[`m3${role[0].toLowerCase()}${role.slice(1)}`]).toLowerCase();
        }
        for (let index = 0; index < 16; index++)
            colours[`term${index}`] = String(palette[`term${index}`]).toLowerCase();
        const ratios = {
            onBackground: Contrast.ratio(palette.m3onBackground, background),
            onSurface: Contrast.ratio(palette.m3onSurface, Contrast.composite(palette.m3surface, surface)),
            onSurfaceVariant: Contrast.ratio(palette.m3onSurfaceVariant, Contrast.composite(palette.m3surfaceVariant, surface)),
            outline: Contrast.ratio(palette.m3outline, Contrast.composite(palette.m3surfaceContainerHighest, surface)),
            inverseOnSurface: Contrast.ratio(palette.m3inverseOnSurface, Contrast.composite(palette.m3inverseSurface, surface))
        };
        for (const role of ["surface", "surfaceDim", "surfaceBright", "surfaceContainerLowest", "surfaceContainerLow", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest", "surfaceVariant"]) {
            const background = Contrast.composite(palette[`m3${role}`], surface);
            ratios[`onSurface:${role}`] = Contrast.ratio(palette.m3onSurface, background);
            ratios[`onSurfaceVariant:${role}`] = Contrast.ratio(palette.m3onSurfaceVariant, background);
            ratios[`outline:${role}`] = Contrast.ratio(palette.m3outline, background);
        }
        for (const role of ["primary", "secondary", "tertiary", "error", "success"]) {
            const capital = role[0].toUpperCase() + role.slice(1);
            ratios[`on${capital}`] = Contrast.ratio(palette[`m3on${capital}`], Contrast.composite(palette[`m3${role}`], surface));
            ratios[`on${capital}Container`] = Contrast.ratio(palette[`m3on${capital}Container`], Contrast.composite(palette[`m3${role}Container`], surface));
            if (["primary", "secondary", "tertiary"].includes(role)) {
                ratios[`on${capital}Fixed`] = Contrast.ratio(palette[`m3on${capital}Fixed`], Contrast.composite(palette[`m3${role}Fixed`], surface));
                ratios[`on${capital}FixedVariant`] = Contrast.ratio(palette[`m3on${capital}FixedVariant`], Contrast.composite(palette[`m3${role}FixedDim`], surface));
            }
        }
        return {
            ratios,
            colours
        };
    }

    Connections {
        target: Integration.Colors
        function onValuesChanged(): void {
            root.staticRevision++;
        }
    }

    IpcHandler {
        target: "paletteContrast"

        function snapshot(preview: bool): string {
            return JSON.stringify({
                source: Services.Colours.source,
                provider: Services.Colours.provider,
                mode: Services.Colours.light ? "light" : "dark",
                current: root.paletteSummary(Services.Colours.current),
                preview: root.paletteSummary(Services.Colours.preview),
                selected: root.paletteSummary(preview ? Services.Colours.preview : Services.Colours.current),
                staticRevision: root.staticRevision,
                staticSource: {
                    background: String(Integration.Colors.background).toLowerCase(),
                    foreground: String(Integration.Colors.foreground).toLowerCase(),
                muted: String(Integration.Colors.muted).toLowerCase(),
                    surface: String(Integration.Colors.surface).toLowerCase(),
                    primary: String(Integration.Colors.primary).toLowerCase(),
                    term0: String(Integration.Colors.palette().term0).toLowerCase(),
                term8: String(Integration.Colors.palette().term8).toLowerCase(),
                palette: root.paletteSummary(Integration.Colors.palette())
                }
            });
        }

        function loadPalette(data: string, preview: bool): bool {
            return Services.Colours.load(data, preview);
        }

        function loadSystem(): bool {
            return Services.Colours.load(JSON.stringify({source: "system", name: "fixture", colours: {}}), false);
        }

        function setPreview(enabled: bool): void {
            Services.Colours.showPreview = enabled;
        }

        function setThemeFile(path: string): int {
            Integration.System.themeFile = path;
            Integration.Colors.reload();
            return root.staticRevision;
        }

        function blackAlter(): string {
            const colour = Services.Colours.alterColour(Qt.rgba(0, 0, 0, 1), 0.8, 1);
            return JSON.stringify({r: colour.r, g: colour.g, b: colour.b, a: colour.a});
        }
    }
}
