pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../styles"

ColumnLayout {
    id: root
    spacing: 14

    UiText {
        Layout.fillWidth: true
        text: "Shades add black, tints add white, and tones adjust saturation with gray. Click a swatch to copy it."
        color: Theme.textSecondary
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }

    Repeater {
        model: ChromackService.data.shades

        ColumnLayout {
            id: section
            required property var modelData
            Layout.fillWidth: true
            spacing: 6

            UiText {
                text: section.modelData.name
                color: Theme.textPrimary
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            UiText {
                Layout.fillWidth: true
                text: section.modelData.description
                color: Theme.textMuted
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 6
                columnSpacing: 0
                rowSpacing: 0

                Repeater {
                    model: section.modelData.colors

                    ChromackSwatch {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 38
                        rounding: 0
                        outlined: false
                        swatchColor: modelData.color
                        value: modelData.css
                        onClicked: ChromackService.copy(value)
                    }
                }
            }
        }
    }
}
