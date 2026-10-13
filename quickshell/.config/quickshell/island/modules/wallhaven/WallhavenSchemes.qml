import QtQuick
import "../../components"
import "../../services"
import "../../styles"

// Palette scheme picker: every scheme is a card with a live swatch strip generated from the
// full-size wallpaper, grouped like Aether's styles, theory and mood modes plus Island's own.
Column {
    id: root
    readonly property int columns: 2
    readonly property real cardWidth: (width - (columns - 1) * 8) / columns
    spacing: 14

    // Background, foreground, accent, then the six ANSI hues.
    function stripColors(palette) {
        if (!palette || !palette.colors) return [];
        const c = palette.colors;
        return [c.background, c.foreground, c.accent, c.red, c.yellow, c.green, c.cyan, c.blue, c.magenta];
    }

    Repeater {
        model: WallhavenService.schemeGroups
        Column {
            id: group
            required property var modelData
            width: root.width
            spacing: 8
            UiText {
                x: 4
                text: group.modelData.title
                color: Theme.textMuted
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 0.8
            }
            Flow {
                width: parent.width
                spacing: 8
                Repeater {
                    model: group.modelData.schemes
                    Rectangle {
                        id: card
                        required property var modelData
                        readonly property var palette: modelData.kind === "aether"
                            ? WallhavenService.previews[WallhavenService.previewMode + ":" + modelData.id] ?? null : null
                        readonly property bool selected: WallhavenService.selectedKind === modelData.kind
                            && WallhavenService.selectedScheme === modelData.id
                        objectName: "wallhaven-scheme-" + modelData.id
                        width: root.cardWidth
                        height: 58
                        radius: 14
                        activeFocusOnTab: true
                        color: selected ? Qt.alpha(Theme.accent, 0.14) : hover.hovered ? Theme.surfaceVariant : Theme.buttonBackground
                        border.width: selected || activeFocus ? 2 : 0
                        border.color: Theme.accent
                        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
                        Accessible.name: modelData.label
                        Accessible.description: modelData.description

                        UiText {
                            id: name
                            x: 12
                            y: 9
                            width: parent.width - 24
                            text: card.modelData.label
                            color: Theme.textPrimary
                            font.pixelSize: 13
                            font.weight: card.selected ? Font.DemiBold : Font.Medium
                            elide: Text.ElideRight
                        }
                        Row {
                            id: strip
                            x: 12
                            y: 34
                            width: parent.width - 24
                            height: 14
                            spacing: 0
                            Repeater {
                                model: root.stripColors(card.palette)
                                Rectangle {
                                    required property string modelData
                                    required property int index
                                    width: strip.width / 9
                                    height: strip.height
                                    color: modelData
                                    topLeftRadius: index === 0 ? 7 : 0
                                    bottomLeftRadius: index === 0 ? 7 : 0
                                    topRightRadius: index === 8 ? 7 : 0
                                    bottomRightRadius: index === 8 ? 7 : 0
                                }
                            }
                        }
                        // Cards without a swatch strip yet (still generating, or Material variants).
                        Rectangle {
                            visible: !card.palette
                            x: 12
                            y: 34
                            width: parent.width - 24
                            height: 14
                            radius: 7
                            color: Theme.surfaceVariant
                            opacity: card.modelData.kind === "aether" && WallhavenService.previewsRunning ? pulse.shimmer : 0.6
                            UiText {
                                visible: card.modelData.kind === "material"
                                anchors.centerIn: parent
                                text: "Rendered by Island on apply"
                                color: Theme.textMuted
                                font.pixelSize: 9
                            }
                        }
                        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: WallhavenService.choose(card.modelData.kind, card.modelData.id) }
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                WallhavenService.choose(card.modelData.kind, card.modelData.id);
                                event.accepted = true;
                            }
                        }
                        IslandTooltip {
                            parent: card
                            visible: hover.hovered
                            text: card.modelData.description
                        }
                    }
                }
            }
        }
    }

    // Shared shimmer for strips that are still being generated.
    Item {
        id: pulse
        property real shimmer: 0.35
        SequentialAnimation on shimmer {
            loops: Animation.Infinite
            running: WallhavenService.previewsRunning
            NumberAnimation { to: 0.75; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
        }
    }
}
