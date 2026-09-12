import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: 10
    BaseInput {
        Layout.fillWidth: true
    }
    Label {
        Layout.fillWidth: true
        text: "Generate complementary values based on color theory."
        color: Style.muted
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }
    Repeater {
        model: ChromackState.data.theory
        ColumnLayout {
            id: scheme
            required property var modelData
            Layout.fillWidth: true
            spacing: 6
            Label {
                text: scheme.modelData.name
                font.bold: true
                font.pixelSize: Style.size("section-title-size", 13)
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 0
                Repeater {
                    model: scheme.modelData.colors
                    Swatch {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: Style.size("preview-height", 34)
                        rounding: 0
                        swatchColor: modelData.color
                        value: modelData.css
                        onClicked: ChromackState.model.copy(value)
                    }
                }
            }
        }
    }
    Label {
        text: "Color Wheel"
        font.bold: true
        font.pixelSize: Style.size("section-title-size", 13)
        Layout.topMargin: 16
    }
    TheoryWheel {
        Layout.fillWidth: true
    }
}
