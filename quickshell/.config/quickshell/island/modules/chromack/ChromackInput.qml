import QtQuick
import QtQuick.Controls
import "../../styles"

// Follows sourceText until the user edits it; submitted fires on Enter or when
// focus leaves with unsaved edits.
TextField {
    id: root
    property string sourceText: ""
    property bool invalid: false
    property bool dirty: false
    signal submitted(string value, bool accepted)
    implicitHeight: 34
    leftPadding: 10
    rightPadding: 10
    color: Theme.textPrimary
    placeholderTextColor: Theme.textMuted
    selectionColor: Theme.accent
    selectedTextColor: Theme.background
    font.family: Theme.uiFontFamily
    font.pixelSize: 13
    selectByMouse: true

    onSourceTextChanged: if (!dirty) text = sourceText
    Component.onCompleted: text = sourceText
    onTextEdited: {
        dirty = true;
        invalid = false;
    }
    onAccepted: {
        dirty = false;
        if (!readOnly)
            submitted(text, true);
    }
    onActiveFocusChanged: {
        if (activeFocus || !dirty)
            return;
        dirty = false;
        if (!readOnly)
            submitted(text, false);
        if (!invalid)
            text = sourceText;
    }

    background: Rectangle {
        radius: 10
        color: Theme.inputBackground
        border.width: 1
        border.color: root.invalid ? Theme.danger : root.activeFocus ? Theme.accent : Theme.inputBorder
    }
}
