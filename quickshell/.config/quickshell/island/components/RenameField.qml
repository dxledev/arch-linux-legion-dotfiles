import QtQuick
import QtQuick.Controls
import "../styles"

// Compact file-name editor: edits the stem while the extension stays fixed and is shown as a suffix.
// Enter and Escape never reach the panel behind it, so neither applies a wallpaper nor closes the island.
TextField {
    id: root
    property string suffix: ""
    // Leaving the field abandons the edit; staged names that should persist turn this off.
    property bool cancelOnBlur: true
    signal committed(string value)
    signal cancelled()

    implicitHeight: 28
    leftPadding: 8
    rightPadding: 8 + suffixLabel.implicitWidth + (suffix ? 2 : 0)
    color: Theme.textPrimary
    placeholderTextColor: Theme.textMuted
    selectionColor: Theme.accent
    selectedTextColor: Theme.background
    font.family: Theme.uiFontFamily
    font.pixelSize: 12
    selectByMouse: true
    verticalAlignment: TextInput.AlignVCenter
    maximumLength: 200

    function begin() {
        forceActiveFocus();
        selectAll();
    }

    Keys.onReturnPressed: root.committed(text)
    Keys.onEnterPressed: root.committed(text)
    Keys.onEscapePressed: root.cancelled()
    // A hidden editor must not keep the focus scope's focus, or it would swallow the keys meant for the list.
    onVisibleChanged: if (!visible) focus = false
    onActiveFocusChanged: if (!activeFocus && cancelOnBlur) root.cancelled()

    background: Rectangle {
        radius: 8
        color: Theme.inputBackground
        border.width: 1
        border.color: root.activeFocus ? Theme.accent : Theme.inputBorder
    }
    UiText {
        id: suffixLabel
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.suffix
        color: Theme.textMuted
        font.pixelSize: 12
    }
}
