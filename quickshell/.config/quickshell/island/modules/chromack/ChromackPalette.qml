pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../styles"

ColumnLayout {
    id: root
    spacing: 6

    UiText {
        Layout.fillWidth: true
        Layout.bottomMargin: 4
        text: ChromackService.data.status || "Generated 24-base palette from " + ChromackService.data.css
        color: Theme.textSecondary
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }

    Repeater {
        model: ChromackService.data.palette

        RowLayout {
            id: row
            required property var modelData
            Layout.fillWidth: true
            spacing: 8

            UiText {
                text: row.modelData.name
                color: Theme.textPrimary
                font.pixelSize: 12
                Layout.preferredWidth: 80
            }

            ChromackSwatch {
                implicitWidth: 52
                implicitHeight: 24
                swatchColor: row.modelData.color
                value: row.modelData.css
                onClicked: ChromackService.copy(value)
            }

            ChromackInput {
                Layout.fillWidth: true
                implicitHeight: 30
                sourceText: row.modelData.css
                readOnly: true
            }

            IconButton {
                implicitWidth: 30
                implicitHeight: 30
                padding: 7
                iconSource: "../assets/icons/copy.svg"
                description: "Copy color"
                focusPolicy: Qt.NoFocus
                onClicked: ChromackService.copy(row.modelData.css)
            }
        }
    }
}
