import QtQuick
import QtQuick.Controls
import "../services"
import "../styles"

Column {
    id: root
    required property string label
    required property var choices
    required property string selected
    signal chosen(string value)
    width: parent.width
    spacing: 8
    opacity: enabled ? 1 : 0.45
    Text { text: root.label; color: Theme.textPrimary; font.pixelSize: 14 }
    ComboBox {
        id: choice
        objectName: "setting-choice-" + root.label
        width: root.width
        height: 40
        model: root.choices
        currentIndex: Math.max(0, root.choices.indexOf(root.selected))
        enabled: !ThemeService.busy
        leftPadding: 14
        rightPadding: 38
        onActivated: root.chosen(currentText)
        contentItem: Text {
            text: choice.displayText
            color: Theme.textSecondary
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        indicator: Text {
            x: choice.width - width - 15
            anchors.verticalCenter: parent.verticalCenter
            text: "⌄"
            font.pixelSize: 18
            color: Theme.textSecondary
        }
        background: Rectangle {
            radius: 14
            color: choice.down ? Theme.buttonPressed : Theme.surfaceVariant
            border.width: choice.activeFocus ? 2 : 0
            border.color: Theme.accent
        }
        delegate: ItemDelegate {
            required property string modelData
            required property int index
            width: choice.width - 12
            height: 36
            highlighted: choice.highlightedIndex === index
            contentItem: Text { text: modelData; color: Theme.textPrimary; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
            background: Rectangle { radius: 12; color: parent.highlighted ? Theme.surfaceVariant : "transparent" }
        }
        popup: Popup {
            y: choice.height + 5
            width: choice.width
            implicitHeight: Math.min(contentItem.implicitHeight + 12, 220)
            padding: 6
            background: Rectangle { radius: 18; color: Theme.surface; border.color: Theme.surfaceVariant }
            contentItem: ListView {
                id: options
                SmoothScroll { scrollTarget: options }
                clip: true
                implicitHeight: contentHeight
                model: choice.popup.visible ? choice.delegateModel : null
                currentIndex: choice.highlightedIndex
                ScrollBar.vertical: ScrollBar {}
            }
        }
    }
}
