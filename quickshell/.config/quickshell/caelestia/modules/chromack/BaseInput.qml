import QtQuick
import QtQuick.Layouts

RowLayout {
    spacing: 8
    Label {
        text: "Base"
    }
    Swatch {
        implicitWidth: Style.size("swatch-size", 24)
        implicitHeight: Style.size("swatch-size", 24)
        swatchColor: ChromackState.model.parse(input.text)
        value: input.text
        onClicked: ChromackState.model.copy(value)
    }
    Input {
        id: input
        objectName: "chromackBase"
        Layout.fillWidth: true
        sourceText: ChromackState.data.hex
        placeholderText: "#5f6b7b or rgba(95, 107, 123, 1)"
        onSubmitted: value => invalid = !ChromackState.model.setColor(value, false, true)
        onAccepted: invalid = !ChromackState.model.generate(text)
    }
    Button {
        text: "Generate"
        onClicked: input.invalid = !ChromackState.model.generate(input.text)
    }
}
