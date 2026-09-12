import QtQuick

Rectangle {
    id: root

    required property string text
    property bool bordered: true
    property color foreground: "white"
    property string fontFamily
    property real fontSize: 11
    property real horizontalPadding: 14
    property real verticalPadding: 4
    signal clicked()

    implicitWidth: label.implicitWidth + horizontalPadding * 2 + 2
    implicitHeight: label.implicitHeight + verticalPadding * 2 + 2
    color: mouse.pressed ? Qt.alpha(foreground, 0.22) : mouse.containsMouse ? Qt.alpha(foreground, 0.08) : "transparent"
    border.width: bordered ? 1 : 0
    border.color: Qt.alpha(foreground, mouse.containsMouse ? 0.25 : 0.4)

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }

}
