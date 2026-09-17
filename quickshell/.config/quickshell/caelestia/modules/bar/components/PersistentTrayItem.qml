import QtQuick
import Caelestia.Config
import qs.components.effects
import qs.services

MouseArea {
    id: root

    required property var modelData

    // There is no real StatusNotifier menu while the app is gone.
    readonly property string popoutName: ""

    acceptedButtons: Qt.LeftButton

    implicitWidth: Tokens.font.body.small.pointSize * 2
    implicitHeight: Tokens.font.body.small.pointSize * 2

    onClicked: TrayPersistence.launch(modelData.id)

    ColouredIcon {
        anchors.fill: parent

        source: TrayPersistence.iconSource(root.modelData)
        colour: Colours.palette.m3secondary
        layer.enabled: Config.bar.tray.recolour
    }
}
