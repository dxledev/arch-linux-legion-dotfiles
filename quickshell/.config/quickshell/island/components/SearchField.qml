import QtQuick
import QtQuick.Controls
import "../services/FocusNavigation.js" as FocusNavigation
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
    // For a field with no list below it: Down steps to the next control.
    function stepDown() {
        if (root.Window.window) FocusNavigation.move(root.Window.window.contentItem, root, 0, 1)
    }
    background: Rectangle {
        radius: 10
        color: Theme.inputBackground
        border.width: 1
        border.color: root.activeFocus ? Theme.accent : Theme.inputBorder
    }
}
