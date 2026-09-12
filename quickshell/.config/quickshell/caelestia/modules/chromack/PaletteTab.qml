import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: 6
    BaseInput {
        Layout.fillWidth: true
    }
    Label {
        Layout.fillWidth: true
        text: ChromackState.data.status || "Generated 24-base palette from " + ChromackState.data.css
        color: Style.muted
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }
    Repeater {
        model: ChromackState.data.palette
        RowLayout {
            id: row
            required property var modelData
            Layout.fillWidth: true
            spacing: 8
            Label {
                text: row.modelData.name
                Layout.preferredWidth: 88
            }
            Swatch {
                implicitWidth: 56
                implicitHeight: 24
                swatchColor: row.modelData.color
                value: row.modelData.css
                onClicked: ChromackState.model.copy(value)
            }
            Input {
                Layout.fillWidth: true
                sourceText: row.modelData.css
                readOnly: true
            }
            Button {
                text: "󰆏"
                glyph: true
                glyphSize: 20
                tooltip: "Copy color"
                onClicked: ChromackState.model.copy(row.modelData.css)
            }
        }
    }
}
