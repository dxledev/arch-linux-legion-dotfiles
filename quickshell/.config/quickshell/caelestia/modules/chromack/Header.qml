import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: Style.gap
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: saveRow.implicitHeight + 16
        visible: ChromackState.savePrompt
        radius: Style.size("header-radius", 12)
        color: Style.value("header-bg", "#1f1d2e")
        RowLayout {
            id: saveRow
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8
            Label {
                text: "Palette name"
            }
            Input {
                id: name
                Layout.fillWidth: true
                sourceText: ChromackState.saveName
                onTextEdited: ChromackState.saveName = text
                onAccepted: save.clicked()
                Connections {
                    target: ChromackState
                    function onSavePromptChanged(): void {
                        if (ChromackState.savePrompt) {
                            name.forceActiveFocus();
                            name.selectAll();
                        }
                    }
                }
            }
            Button {
                text: "Cancel"
                onClicked: ChromackState.savePrompt = false
            }
            Button {
                id: save
                text: "Save"
                onClicked: {
                    if (ChromackState.model.savePalette(name.text))
                        ChromackState.savePrompt = false;
                }
            }
        }
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + 16
        radius: Style.size("header-radius", 12)
        color: Style.value("header-bg", "#1f1d2e")
        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    text: ChromackState.data.title
                    font.bold: true
                    font.pixelSize: Style.size("title-size", 17)
                }
                Label {
                    Layout.fillWidth: true
                    text: ChromackState.data.subtitle
                    color: Style.muted
                    font.pixelSize: Style.size("subtitle-size", 12)
                    elide: Text.ElideRight
                }
            }
            Button {
                text: ""
                glyph: true
                tooltip: "Save palette"
                onClicked: ChromackState.savePrompt = !ChromackState.savePrompt
            }
            Button {
                text: ""
                glyph: true
                tooltip: "Pick a color from the screen"
                onClicked: ChromackState.pick()
            }
            Button {
                objectName: "chromackClose"
                text: "X"
                danger: true
                tooltip: "Close"
                onClicked: ChromackState.close(true)
            }
        }
    }
}
