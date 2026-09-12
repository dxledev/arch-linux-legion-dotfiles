import QtQuick
import QtQuick.Controls
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property WeatherLocations locations
    width: Math.max(180, labels.width + Tokens.padding.medium * 2 + 8)
    height: entries.implicitHeight + 8
    visible: false
    z: 30
    radius: Tokens.rounding.small
    color: Colours.palette.m3surfaceContainer
    border.width: 1
    border.color: Colours.palette.m3outline

    function open(): void { visible = true; }
    function close(): void { visible = false; }

    Keys.onEscapePressed: close()

    TextMetrics {
        id: labels
        font: Tokens.font.body.medium
        text: root.locations.locations.reduce((longest, entry) => entry.displayName.length > longest.length ? entry.displayName : longest, "")
    }

    Column {
        id: entries
        x: 4
        y: 4
        width: parent.width - 8
        spacing: 4

        Repeater {
            model: root.locations.locations

            ItemDelegate {
                id: option
                required property var modelData
                required property int index
                width: entries.width
                height: contentItem.implicitHeight + topPadding + bottomPadding
                leftPadding: Tokens.padding.medium
                rightPadding: Tokens.padding.medium
                topPadding: Tokens.padding.small
                bottomPadding: Tokens.padding.small
                highlighted: root.locations.selectedIndex === index
                onClicked: {
                    root.locations.select(index);
                    root.close();
                }

                background: StyledRect {
                    radius: Tokens.rounding.small
                    color: option.highlighted ? Colours.palette.m3primary : option.hovered ? Colours.palette.m3surfaceContainerHigh : Colours.palette.m3surface
                }

                contentItem: Column {
                    spacing: Tokens.spacing.extraSmall
                    StyledText {
                        text: option.modelData.displayName
                        font: Tokens.font.body.medium
                        color: option.highlighted ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    }
                    StyledText {
                        text: option.modelData.latitude.toFixed(4) + ", " + option.modelData.longitude.toFixed(4)
                        font: Tokens.font.body.small
                        color: option.highlighted ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }
    }
}
