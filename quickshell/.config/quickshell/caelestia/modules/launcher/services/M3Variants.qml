pragma Singleton

import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.services
import qs.utils
import qs.services

Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}variant `.length);
    }

    property var savedAetherPalettes: []
    property bool refreshPending: false

    Component.onCompleted: reloadAether()

    function titleCase(value: string): string {
        return value.replace(/[-_.]/g, " ").split(/\s+/).map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(" ");
    }

    function reloadAether(): void {
        if (getAetherPalettes.running)
            refreshPending = true;
        else
            getAetherPalettes.running = true;
    }

    function query(search: string): var {
        const raw = transformSearch(search).replace(/\s+/g, " ");
        const trimmed = raw.trim();
        if (/^aether\s+/i.test(raw))
            return aetherPaletteSearch.query(trimmed.slice("aether".length).trim());
        if (trimmed.toLowerCase() === "aether")
            return savedAetherPalettes.length ? [aetherMenu] : [];

        const variants = variantSearch.query(trimmed);
        if (!savedAetherPalettes.length)
            return variants;
        return [...variants, ...aetherMenuSearch.query(trimmed)];
    }

    property list<QtObject> allVariants: [
        Variant {
            variant: "vibrant"
            icon: "sentiment_very_dissatisfied"
            name: Tr.trCtx("Vibrant", "M3 scheme variant name")
            description: Tr.tr("A high chroma palette. The primary palette's chroma is at maximum.")
        },
        Variant {
            variant: "tonalspot"
            icon: "android"
            name: Tr.trCtx("Tonal Spot", "M3 scheme variant name")
            description: Tr.tr("Default for Material theme colours. A pastel palette with a low chroma.")
        },
        Variant {
            variant: "expressive"
            icon: "compare_arrows"
            name: Tr.trCtx("Expressive", "M3 scheme variant name")
            description: Tr.tr("A medium chroma palette. The primary palette's hue is different from the seed colour, for variety.")
        },
        Variant {
            variant: "fidelity"
            icon: "compare"
            name: Tr.trCtx("Fidelity", "M3 scheme variant name")
            description: Tr.tr("Matches the seed colour, even if the seed colour is very bright (high chroma).")
        },
        Variant {
            variant: "content"
            icon: "sentiment_calm"
            name: Tr.trCtx("Content", "M3 scheme variant name")
            description: Tr.tr("Almost identical to fidelity.")
        },
        Variant {
            variant: "fruitsalad"
            icon: "nutrition"
            name: Tr.trCtx("Fruit Salad", "M3 scheme variant name")
            description: Tr.tr("A playful theme - the seed colour's hue does not appear in the theme.")
        },
        Variant {
            variant: "rainbow"
            icon: "looks"
            name: Tr.trCtx("Rainbow", "M3 scheme variant name")
            description: Tr.tr("A playful theme - the seed colour's hue does not appear in the theme.")
        },
        Variant {
            variant: "neutral"
            icon: "contrast"
            name: Tr.trCtx("Neutral", "M3 scheme variant name")
            description: Tr.tr("Close to greyscale, a hint of chroma.")
        },
        Variant {
            variant: "monochrome"
            icon: "filter_b_and_w"
            name: Tr.trCtx("Monochrome", "M3 scheme variant name")
            description: Tr.tr("All colours are greyscale, no chroma.")
        }
    ]
    list: allVariants
    useFuzzy: GlobalConfig.launcher.useFuzzy.variants

    Searcher {
        id: variantSearch
        list: root.allVariants
        useFuzzy: GlobalConfig.launcher.useFuzzy.variants
    }

    Searcher {
        id: aetherMenuSearch
        list: [aetherMenu]
        useFuzzy: GlobalConfig.launcher.useFuzzy.variants
    }

    Searcher {
        id: aetherPaletteSearch
        list: aetherPaletteVariants.instances
        useFuzzy: GlobalConfig.launcher.useFuzzy.variants
        keys: ["name", "style", "mode"]
        weights: [4, 2, 1]
    }

    QtObject {
        id: aetherMenu

        readonly property string kind: "aether-menu"
        readonly property string name: Tr.tr("Aether")
        readonly property string description: Tr.tr("Saved Aether palettes for this wallpaper")
        readonly property string icon: "palette"

        function onClicked(list: AppList): void {
            list.search.text = `${GlobalConfig.launcher.actionPrefix}variant aether `;
        }
    }

    Variants {
        id: aetherPaletteVariants

        model: root.savedAetherPalettes
        AetherPalette {}
    }

    Process {
        id: getAetherPalettes

        command: [Colours.controller, "list-aether"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    root.savedAetherPalettes = JSON.parse(stdout.text).sort((a, b) => a.style.localeCompare(b.style) || a.mode.localeCompare(b.mode));
                } catch (error) {
                    root.savedAetherPalettes = [];
                    console.warn("Could not parse saved Aether palettes:", error);
                }
            } else {
                root.savedAetherPalettes = [];
                console.warn("Could not load saved Aether palettes:", stderr.text);
            }
            if (root.refreshPending) {
                root.refreshPending = false;
                root.reloadAether();
            }
        }
    }

    Connections {
        target: Wallpapers

        function onActualCurrentChanged(): void {
            wallpaperRefresh.restart();
        }
    }

    Connections {
        target: Colours

        function onPaletteRevisionChanged(): void {
            root.reloadAether();
        }
    }

    Timer {
        id: wallpaperRefresh
        interval: 500
        onTriggered: root.reloadAether()
    }

    component Variant: QtObject {
        required property string variant
        required property string icon
        required property string name
        required property string description

        function onClicked(list: AppList): void {
            if (Colours.source !== "dynamic")
                return;
            list.screenState.launcher = false;
            Colours.setVariant(variant);
        }
    }

    component AetherPalette: QtObject {
        required property var modelData
        readonly property string kind: "aether"
        readonly property string style: modelData.style
        readonly property string mode: modelData.mode
        readonly property string name: `${root.titleCase(style)} · ${root.titleCase(mode)}`
        readonly property string description: Tr.tr("Aether extraction palette")
        readonly property string icon: "palette"

        function onClicked(list: AppList): void {
            if (Colours.source !== "dynamic")
                return;
            list.screenState.launcher = false;
            Colours.setAetherVariant(style, mode);
        }
    }
}
