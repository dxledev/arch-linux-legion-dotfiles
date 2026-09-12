import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: 10
    BaseInput {
        Layout.fillWidth: true
    }
    Label {
        Layout.fillWidth: true
        text: "Shades add black, tints add white, and tones adjust saturation with gray."
        color: Style.muted
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }
    Repeater {
        model: ChromackState.data.shades
        ColumnLayout {
            id: section
            required property var modelData
            Layout.fillWidth: true
            spacing: 6
            Label {
                text: section.modelData.name
                font.bold: true
                font.pixelSize: Style.size("section-title-size", 13)
            }
            Label {
                Layout.fillWidth: true
                text: section.modelData.description
                color: Style.muted
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
            GridLayout {
                Layout.fillWidth: true
                columns: 6
                columnSpacing: 0
                rowSpacing: 0
                Repeater {
                    model: section.modelData.colors
                    Swatch {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        rounding: 0
                        swatchColor: modelData.color
                        value: modelData.css
                        onClicked: ChromackState.model.copy(value)
                    }
                }
            }
        }
    }
}
