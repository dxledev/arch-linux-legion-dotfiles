import QtQuick
import QtQuick.Controls as QQC

QQC.TextField {
    id: root
    property string sourceText: ""
    property bool invalid: false
    signal submitted(string value)
    implicitHeight: Style.inputHeight
    color: Style.text
    selectionColor: Style.primary
    selectedTextColor: Style.panel
    placeholderTextColor: Style.muted
    font.family: Style.font
    font.pixelSize: Style.inputFontSize
    leftPadding: 10
    rightPadding: 10
    selectByMouse: true
    onSourceTextChanged: if (!activeFocus)
        text = sourceText
    Component.onCompleted: text = sourceText
    onEditingFinished: if (!readOnly)
        submitted(text)
    background: Rectangle {
        color: Style.input
        radius: Style.inputRadius
        border.color: root.invalid ? Style.danger : root.activeFocus ? Style.primary : Style.border
        border.width: 1
    }
}
