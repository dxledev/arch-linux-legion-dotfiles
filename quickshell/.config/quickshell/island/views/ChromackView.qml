import QtQuick
import "../components"
import "../core"
import "../styles"

// Loads Chromack on demand so the Shell.Chromack plugin is only required while
// the panel is open; the rest of Island keeps working without it.
FocusScope {
    id: root
    implicitWidth: 900
    implicitHeight: 620
    focus: true

    Keys.onEscapePressed: IslandController.reset()

    Loader {
        id: panel
        objectName: "chromack-panel-loader"
        anchors.fill: parent
        focus: true
        source: "../modules/chromack/ChromackPanel.qml"
    }

    Column {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 18
        visible: panel.status === Loader.Error

        PanelHeader {
            title: "Chromack"
            onBack: IslandController.openNavigation()
        }

        UiText {
            objectName: "chromack-unavailable"
            width: parent.width
            text: "Chromack unavailable. Build the Shell.Chromack plugin with scripts/build-chromack."
            color: Theme.danger
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }
    }
}
