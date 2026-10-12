import QtQuick
import "../components"
import "../core"
import "../styles"

// Loads the clipboard panel on demand so the Shell.Clipboard plugin is only
// required while the panel is open; the rest of Island keeps working without it.
FocusScope {
    id: root
    implicitWidth: 900
    implicitHeight: 620
    focus: true

    Keys.onEscapePressed: IslandController.reset()

    Loader {
        id: panel
        objectName: "clipboard-panel-loader"
        anchors.fill: parent
        focus: true
        source: "../modules/clipboard/ClipboardPanel.qml"
    }

    Column {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 18
        visible: panel.status === Loader.Error

        PanelHeader {
            title: "Clipboard"
            onBack: IslandController.openNavigation()
        }

        UiText {
            objectName: "clipboard-unavailable"
            width: parent.width
            text: "Clipboard manager unavailable. Build the Shell.Clipboard plugin (caelestia/integration/clipboard) into .runtime/qml."
            color: Theme.danger
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }
    }
}
