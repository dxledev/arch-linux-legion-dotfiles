pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components"
import "../../core"
import "../../styles"

FocusScope {
    id: root
    implicitWidth: 900
    implicitHeight: 620
    focus: true

    readonly property var tabs: [
        { label: "Shades", icon: "list.svg" },
        { label: "Palette", icon: "palette.svg" },
        { label: "Theory", icon: "sparkles.svg" }
    ]
    readonly property var pages: [shadesPage, palettePage, theoryPage]
    property string openedMaterials: ""

    function materialsSnapshot() {
        return JSON.stringify((ChromackService.data.materials ?? []).map(material => material.css));
    }

    function selectTab(index) {
        ChromackService.tab = (index + tabs.length) % tabs.length;
    }

    function toggleSavePrompt() {
        ChromackService.savePrompt = !ChromackService.savePrompt;
        if (ChromackService.savePrompt) {
            saveName.text = ChromackService.saveName;
            saveName.forceActiveFocus();
            saveName.selectAll();
        } else {
            picker.hexInput?.forceActiveFocus();
        }
    }

    function savePalette() {
        ChromackService.saveName = saveName.text;
        if (ChromackService.model.savePalette(saveName.text).length > 0) {
            ChromackService.savePrompt = false;
            picker.hexInput?.forceActiveFocus();
        }
    }

    Component.onCompleted: {
        ChromackService.savePrompt = false;
        ChromackService.model.reload();
        openedMaterials = materialsSnapshot();
        Qt.callLater(() => picker.hexInput?.forceActiveFocus());
    }
    // Persist edited material slots to the shared CSS files when the panel closes.
    Component.onDestruction: {
        if (materialsSnapshot() !== openedMaterials)
            ChromackService.model.flush();
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            if (ChromackService.savePrompt)
                root.toggleSavePrompt();
            else
                IslandController.reset();
        } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_P) {
            ChromackService.pick();
        } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_S) {
            root.toggleSavePrompt();
        } else if (event.modifiers & Qt.ControlModifier && event.key >= Qt.Key_1 && event.key <= Qt.Key_3) {
            root.selectTab(event.key - Qt.Key_1);
        } else if (event.modifiers & Qt.ControlModifier && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
            root.selectTab(ChromackService.tab + (event.key === Qt.Key_Backtab ? -1 : 1));
        } else {
            return;
        }
        event.accepted = true;
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        PanelHeader {
            Layout.fillWidth: true
            title: "Chromack"
            subtitle: ChromackService.data.subtitle ?? ""
            titleActionIcon: "../assets/icons/pipette.svg"
            titleActionDescription: "Pick a color from the screen"
            titleActionActive: ChromackService.picking
            trailingText: ChromackService.savePrompt ? "Cancel save" : "Save palette"
            trailingClickable: true
            scrollTargets: [pageScroll]
            onBack: IslandController.openNavigation()
            onTitleActionClicked: ChromackService.pick()
            onTrailingClicked: root.toggleSavePrompt()
        }

        Rectangle {
            objectName: "chromack-save-prompt"
            Layout.fillWidth: true
            Layout.preferredHeight: ChromackService.savePrompt ? saveRow.implicitHeight + 16 : 0
            visible: Layout.preferredHeight > 0
            clip: true
            radius: 14
            color: Theme.surface
            Behavior on Layout.preferredHeight { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }

            RowLayout {
                id: saveRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 8
                spacing: 8

                UiText {
                    Layout.leftMargin: 6
                    text: "Palette name"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                }

                ChromackInput {
                    id: saveName
                    objectName: "chromack-save-name"
                    Layout.fillWidth: true
                    sourceText: ChromackService.saveName
                    onSubmitted: (value, accepted) => { if (accepted) root.savePalette(); }
                }

                TextActionButton {
                    objectName: "chromack-save-cancel"
                    text: "Cancel"
                    onClicked: root.toggleSavePrompt()
                }

                TextActionButton {
                    objectName: "chromack-save-confirm"
                    text: "Save"
                    onClicked: root.savePalette()
                }
            }
        }

        UiText {
            objectName: "chromack-error"
            Layout.fillWidth: true
            visible: ChromackService.errorMessage.length > 0
            text: ChromackService.errorMessage
            color: Theme.danger
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            ChromackPicker {
                id: picker
                objectName: "chromack-picker"
                Layout.preferredWidth: 400
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignTop
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: Theme.border
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                Row {
                    objectName: "chromack-tabs"
                    spacing: 6

                    Repeater {
                        model: root.tabs

                        Button {
                            id: chip
                            required property var modelData
                            required property int index
                            readonly property bool selected: ChromackService.tab === index
                            objectName: "chromack-tab-" + modelData.label.toLowerCase()
                            implicitHeight: 30
                            leftPadding: 10
                            rightPadding: 12
                            hoverEnabled: true
                            focusPolicy: Qt.NoFocus
                            onClicked: root.selectTab(index)

                            HoverHandler { cursorShape: Qt.PointingHandCursor }

                            contentItem: Row {
                                spacing: 6
                                SvgIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: "../assets/icons/" + chip.modelData.icon
                                    size: 14
                                    color: chip.selected ? Theme.background : Theme.textSecondary
                                }
                                UiText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: chip.modelData.label
                                    color: chip.selected ? Theme.background : Theme.textPrimary
                                    font.pixelSize: 12
                                }
                            }

                            background: Rectangle {
                                radius: height / 2
                                color: chip.selected ? Theme.accent
                                    : chip.down ? Theme.buttonPressed : chip.hovered ? Theme.surfaceVariant : Theme.surface
                                Behavior on color { ColorAnimation { duration: Theme.animationFast } }
                            }
                        }
                    }
                }

                Flickable {
                    id: pageScroll
                    objectName: "chromack-page-scroll"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: page.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    Loader {
                        id: page
                        objectName: "chromack-page"
                        width: pageScroll.width - 10
                        sourceComponent: root.pages[ChromackService.tab] ?? null
                        onLoaded: pageScroll.contentY = 0
                    }
                }
            }
        }

        UiText {
            objectName: "chromack-footer"
            Layout.fillWidth: true
            text: "Click swatches to copy    Enter Generate    Ctrl+P Eyedropper    Ctrl+S Save palette    Ctrl+1–3 Tabs    Esc Close"
            color: Theme.textMuted
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }

    Component { id: shadesPage; ChromackShades {} }
    Component { id: palettePage; ChromackPalette {} }
    Component { id: theoryPage; ChromackTheory {} }
}
