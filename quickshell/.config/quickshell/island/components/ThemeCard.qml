import QtQuick
import "../styles"

Rectangle {
    id: root

    property string themeName: ""
    property string themeId: ""

    property color backgroundColor: Theme.previewBackground

    property color color1: Theme.accent
    property color color2: Theme.textSecondary
    property color color3: Theme.border
    property color color4: Theme.warning

    property color accentColor: Theme.accent
    property color textColor: Theme.previewText

    property bool selected: false
    property real swatchSize: 19.2

    width: 160
    height: 80

    radius: 16

    color: backgroundColor

    border.width: selected ? 3 : 1
    border.color: selected ? Theme.accent : Theme.border

    Column {

        anchors.fill: parent

        anchors.margins: 12
        anchors.topMargin: 15
        anchors.bottomMargin: 9

        spacing: 6

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            Rectangle {
                width: root.swatchSize
                height: width
                radius: width / 2
                color: root.color1
            }

            Rectangle {
                width: root.swatchSize
                height: width
                radius: width / 2
                color: root.color2
            }

            Rectangle {
                width: root.swatchSize
                height: width
                radius: width / 2
                color: root.color3
            }
            Rectangle {
                width: root.swatchSize
                height: width
                radius: width / 2
                color: root.color4
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 70
            height: 4

            radius: 2

            color: root.accentColor
            transform: Translate { y: 2 }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.themeName

            color: root.textColor

            font.pixelSize: 13

            font.bold: true
        }
    }
}
