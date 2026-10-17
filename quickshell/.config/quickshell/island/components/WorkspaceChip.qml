import QtQuick
import "../styles"

// A small round button for the expanded island's workspace section: a number, a glyph from the
// icon font, or an SVG. `dimmed` greys it out (an empty special workspace) without disabling it.
Rectangle {
    id: root

    property string text: ""
    property url iconSource
    property bool active: false
    property bool dimmed: false
    property color iconColor: Theme.textPrimary
    property string description: ""
    property int fontSize: 13
    signal clicked
    signal rightClicked

    // Keyboard: Enter or Space presses it; Shift+Enter or the Menu key right-clicks.
    activeFocusOnTab: true
    border.width: activeFocus ? 2 : 0
    border.color: Theme.accent
    Keys.onPressed: event => {
        const press = event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space;
        if (event.key === Qt.Key_Menu || (press && (event.modifiers & Qt.ShiftModifier))) root.rightClicked();
        else if (press) root.clicked();
        else return;
        event.accepted = true;
    }

    implicitWidth: 32
    implicitHeight: 28
    radius: height / 2
    // Rests, hovers and presses as lighter shades of the surface (the hover colours can match the theme's own).
    function lift(amount) {
        return Qt.tint(Theme.surface, Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, amount));
    }
    color: active ? Theme.accent : mouse.pressed ? lift(0.26) : mouse.containsMouse ? lift(0.18) : lift(0.1)
    opacity: dimmed && !active ? 0.4 : 1
    Accessible.role: Accessible.Button
    Accessible.name: description
    Behavior on color { ColorAnimation { duration: Theme.animationFast } }
    Behavior on opacity { NumberAnimation { duration: Theme.animationFast } }

    UiText {
        anchors.centerIn: parent
        visible: root.iconSource == ""
        text: root.text
        color: root.active ? Theme.background : Theme.textPrimary
        font.family: /^\d+$/.test(root.text) ? Theme.uiFontFamily : Theme.iconFont
        font.pixelSize: root.fontSize
        font.weight: Font.Medium
    }
    SvgIcon {
        anchors.centerIn: parent
        visible: root.iconSource != ""
        source: root.iconSource
        color: root.active ? Theme.background : root.iconColor
        size: 16
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
    IslandTooltip {
        parent: root
        visible: mouse.containsMouse && root.description.length > 0
        text: root.description
    }
}
