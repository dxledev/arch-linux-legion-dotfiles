import QtQuick
import QtQuick.Controls
import "../island"
import "../services"
import "../styles"

Column {
    id: root
    required property string label
    required property var choices
    required property string selected
    property var choiceLabel: value => value
    // Opt in to a play button on every choice, and one beside the dropdown for the one chosen. previewing is the
    // choice being played now, whose button then stops it.
    property bool previewable: false
    property string previewing: ""
    // Opt in to keeping the list inside an item (a panel): when it would run past the item's bottom edge it opens
    // upward instead.
    property Item within: null
    property bool opensUp: false
    signal chosen(string value)
    signal previewToggled(string value)

    component PreviewButton: AbstractButton {
        id: previewButton
        property bool playing: false
        hoverEnabled: true
        focusPolicy: Qt.TabFocus
        Accessible.name: playing ? "Stop preview" : "Play preview"
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        contentItem: Item {
            SvgIcon {
                anchors.centerIn: parent
                source: previewButton.playing ? "../assets/icons/stop.svg" : "../assets/icons/player-play.svg"
                size: 16
                color: Theme.textPrimary
            }
        }
        background: Rectangle {
            radius: height / 2
            color: previewButton.down ? Theme.buttonPressed : previewButton.hovered ? Theme.buttonHover : Theme.surfaceVariant
            border.width: previewButton.activeFocus ? 2 : 0
            border.color: Theme.accent
        }
    }
    width: parent.width
    spacing: 8
    opacity: enabled ? 1 : 0.45
    // An empty label leaves the dropdown on its own, for a row that already says what it is.
    UiText { visible: text.length > 0; text: root.label; color: Theme.textPrimary; font.pixelSize: 14 }
    ComboBox {
        id: choice
        focusPolicy: Qt.TabFocus
        objectName: "setting-choice-" + root.label
        width: root.width - (root.previewable ? 48 : 0)
        height: 40
        model: root.choices
        displayText: root.choiceLabel(currentText)
        currentIndex: Math.max(0, root.choices.indexOf(root.selected))
        enabled: !ThemeService.busy
        leftPadding: 14
        rightPadding: 38
        onActivated: root.chosen(currentText)
        contentItem: UiText {
            text: choice.displayText
            color: Theme.textSecondary
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        indicator: UiText {
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
        PreviewButton {
            objectName: "setting-choice-preview-selected"
            visible: root.previewable
            x: choice.width + 8
            width: 40
            height: 40
            playing: root.previewing !== "" && root.previewing === root.selected
            onClicked: root.previewToggled(root.selected)
        }
        delegate: ItemDelegate {
            id: row
            required property string modelData
            required property int index
            width: choice.width - 12
            height: 36
            highlighted: choice.highlightedIndex === index
            contentItem: Item {
                UiText {
                    anchors.fill: parent
                    anchors.rightMargin: root.previewable ? 40 : 0
                    text: root.choiceLabel(modelData)
                    color: Theme.textPrimary
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                PreviewButton {
                    objectName: "setting-choice-preview-" + row.modelData
                    visible: root.previewable
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 30
                    playing: root.previewing !== "" && root.previewing === row.modelData
                    onClicked: root.previewToggled(row.modelData)
                }
            }
            background: Rectangle { radius: 12; color: parent.highlighted ? Theme.surfaceVariant : "transparent" }
        }
        popup: Popup {
            y: root.opensUp ? -height - 5 : choice.height + 5
            onAboutToShow: root.opensUp = root.within !== null
                && choice.mapToItem(root.within, 0, choice.height + 5 + Math.min(choice.count * 36 + 12, 220)).y > root.within.height
            width: choice.width
            implicitHeight: Math.min(contentItem.implicitHeight + 12, 220)
            padding: 6
            onOpened: IslandState.dropdownArea = background
            onClosed: if (IslandState.dropdownArea === background) IslandState.dropdownArea = null
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
