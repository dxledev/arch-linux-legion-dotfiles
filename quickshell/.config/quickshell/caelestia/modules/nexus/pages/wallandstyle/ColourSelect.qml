import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common
import qs.modules.launcher.services

PageBase {
    id: root

    title: Tr.tr("Colours")
    isSubPage: true

    function formattedThemeName(name: string): string {
        if (name === "rose-pine")
            return "Rosé Pine";
        if (!name)
            return Tr.tr("Static");
        return name.replace(/[-_]/g, " ").split(/\s+/).map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(" ");
    }

    function formattedAetherStyle(style: string): string {
        return style.replace(/[-_.]/g, " ").split(/\s+/).map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(" ");
    }

    function formattedAetherVariant(): string {
        const style = Colours.aetherStyle ? ` · ${root.formattedAetherStyle(Colours.aetherStyle)}` : "";
        const mode = Colours.light ? Tr.tr("Light") : Tr.tr("Dark");
        return `${Tr.tr("Aether")}${style} · ${mode}`;
    }

    function hexColour(value: color): string {
        const hex = [value.r, value.g, value.b]
            .map(channel => Math.round(channel * 255).toString(16).padStart(2, "0"))
            .join("");
        return `#${hex.toUpperCase()}`;
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: themeLayout.implicitHeight + Tokens.padding.large * 2
            color: Colours.current.m3surfaceContainer
            radius: Tokens.rounding.large

            RowLayout {
                id: themeLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.large

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Theme")
                        color: Colours.current.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        horizontalAlignment: Colours.source === "dynamic" ? Text.AlignLeft : Text.AlignHCenter
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Colours.source === "dynamic" ? Tr.tr("Dynamic") : root.formattedThemeName(Colours.staticThemeName)
                        color: Colours.current.m3onSurface
                        font: Tokens.font.title.small
                        elide: Text.ElideRight
                        horizontalAlignment: Colours.source === "dynamic" ? Text.AlignLeft : Text.AlignHCenter
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall
                    visible: Colours.source === "dynamic"

                    StyledText {
                        text: Tr.tr("Variant")
                        color: Colours.current.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Colours.provider === "aether"
                            ? root.formattedAetherVariant()
                            : M3Variants.allVariants.find(item => item.variant === Colours.variant)?.name ?? Colours.variant
                        color: Colours.current.m3onSurface
                        font: Tokens.font.title.small
                        elide: Text.ElideRight
                    }
                }
            }
        }

        StyledText {
            text: Tr.tr("Key colours")
            color: Colours.current.m3onSurface
            font: Tokens.font.title.small
        }

        Repeater {
            model: [
                { label: Tr.tr("Primary"), colour: Colours.current.m3primary_paletteKeyColor },
                { label: Tr.tr("Secondary"), colour: Colours.current.m3secondary_paletteKeyColor },
                { label: Tr.tr("Tertiary"), colour: Colours.current.m3tertiary_paletteKeyColor },
                { label: Tr.tr("Neutral"), colour: Colours.current.m3neutral_paletteKeyColor },
                { label: Tr.tr("Neutral variant"), colour: Colours.current.m3neutral_variant_paletteKeyColor }
            ]

            delegate: StyledRect {
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: swatchLayout.implicitHeight + Tokens.padding.medium * 2
                color: Colours.current.m3surfaceContainer
                radius: Tokens.rounding.large

                RowLayout {
                    id: swatchLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    spacing: Tokens.spacing.medium

                    StyledRect {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        color: modelData.colour
                        radius: Tokens.rounding.medium
                        border.color: Colours.current.m3outlineVariant
                        border.width: 1
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.label
                        color: Colours.current.m3onSurface
                        font: Tokens.font.body.large
                    }

                    StyledText {
                        text: root.hexColour(modelData.colour)
                        color: Colours.current.m3onSurfaceVariant
                        font: Tokens.font.mono.small
                    }
                }
            }
        }
    }
}
