pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../styles"

ColumnLayout {
    id: root
    spacing: 12

    UiText {
        Layout.fillWidth: true
        text: "Complementary values based on color theory. Click a swatch or wheel segment to copy it."
        color: Theme.textSecondary
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }

    Repeater {
        model: ChromackService.data.theory

        ColumnLayout {
            id: scheme
            required property var modelData
            Layout.fillWidth: true
            spacing: 6

            UiText {
                text: scheme.modelData.name
                color: Theme.textPrimary
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: scheme.modelData.colors

                    ChromackSwatch {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 30
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

    UiText {
        Layout.topMargin: 8
        text: "Color wheel"
        color: Theme.textPrimary
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }

    ChromackWheel {
        objectName: "chromack-wheel"
        Layout.fillWidth: true
        implicitHeight: 340
    }
}
