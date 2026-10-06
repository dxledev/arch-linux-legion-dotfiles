import QtQuick
import "../styles"

Column {
    id: root
    required property string title
    required property url iconSource
    default property alias content: body.data
    width: parent.width
    spacing: 10
    Row {
        x: 8
        spacing: 9
        SvgIcon { source: root.iconSource; size: 17; color: Theme.accent }
        UiText { text: root.title; color: Theme.textSecondary; font.pixelSize: 13; font.weight: Font.DemiBold }
    }
    Rectangle {
        width: root.width
        height: body.implicitHeight + 28
        radius: 26
        color: Theme.surface
        Column {
            id: body
            x: 18
            y: 14
            width: parent.width - 36
            spacing: 14
        }
    }
}
