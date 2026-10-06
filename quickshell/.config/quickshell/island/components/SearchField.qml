import QtQuick
import QtQuick.Controls
import "../styles"

TextField {
    id: root
    implicitHeight: 40
    leftPadding: 12
    rightPadding: 12
    color: Theme.textPrimary
    placeholderTextColor: Theme.textMuted
    selectionColor: Theme.accent
    selectedTextColor: Theme.background
    font.family: Theme.uiFontFamily
    font.pixelSize: 14
    selectByMouse: true
    signal navigateDown()
    Keys.onDownPressed: navigateDown()
    background: Rectangle {
        radius: 10
        color: Theme.inputBackground
        border.width: 1
        border.color: root.activeFocus ? Theme.accent : Theme.inputBorder
    }
}
