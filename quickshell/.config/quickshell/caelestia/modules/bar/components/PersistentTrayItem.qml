import QtQuick
import Caelestia.Config
import qs.components.effects
import qs.modules.bar.components.status
import qs.services
import qs.utils

MouseArea {
    id: root

    required property var modelData
    readonly property bool sunshineTray: Icons.isSunshineTray(
        modelData.id,
        modelData.title,
        "",
        modelData.icon
    )

    // There is no real StatusNotifier menu while the app is gone.
    readonly property string popoutName: ""

    acceptedButtons: Qt.LeftButton

    implicitWidth: Tokens.font.body.small.pointSize * 2
    implicitHeight: Tokens.font.body.small.pointSize * 2

    onClicked: TrayPersistence.launch(modelData.id)

    ColouredIcon {
        anchors.fill: parent
        visible: !root.sunshineTray

        source: TrayPersistence.iconSource(root.modelData)
        colour: Colours.palette.m3secondary
        layer.enabled: Config.bar.tray.recolour
    }

    SunshineIcon {
        anchors.fill: parent
        visible: root.sunshineTray
        colour: Colours.palette.m3secondary
    }
}
