import QtQuick
import "../../components"
import "../../styles"

// Toggle pill used for sorting, categories, purity and every filter option.
Rectangle {
    id: root
    property string text: ""
    property bool checked: false
    property color tint: Theme.accent
    property color swatch: "transparent"
    property string description: ""
    signal clicked()

    objectName: "wallhaven-chip-" + text

    implicitHeight: 28
    implicitWidth: row.implicitWidth + 22
    radius: height / 2
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.4
    color: checked ? Qt.alpha(tint, 0.2) : hover.hovered ? Theme.surfaceVariant : Theme.buttonBackground
    border.width: activeFocus ? 2 : checked ? 1 : 0
    border.color: activeFocus ? Theme.accent : tint
    Behavior on color { ColorAnimation { duration: Theme.animationFast } }
    Accessible.name: text
    Accessible.role: Accessible.CheckBox
    Accessible.checked: checked

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Rectangle {
            visible: root.swatch.a > 0
            anchors.verticalCenter: parent.verticalCenter
            width: 10; height: 10; radius: 5
            color: root.swatch
        }
        UiText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.pixelSize: 12
            font.weight: root.checked ? Font.DemiBold : Font.Normal
            color: root.checked ? Theme.textPrimary : Theme.textSecondary
        }
    }
    HoverHandler { id: hover; enabled: root.enabled; cursorShape: Qt.PointingHandCursor }
    TapHandler { enabled: root.enabled; onTapped: root.clicked() }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.clicked();
            event.accepted = true;
        }
    }
    IslandTooltip {
        parent: root
        visible: hover.hovered && root.description.length > 0
        text: root.description
    }
}
