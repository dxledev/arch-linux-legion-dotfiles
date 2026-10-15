import QtQuick
import Quickshell.Widgets
import "../styles"

Rectangle {


    id: root

    property string imageSource: ""
    property bool selected: false
    // The applied wallpaper is dimmed; the keyboard selection gets the outline.
    property bool active: false
    // Marked for deletion: tinted with the danger colour and badged with a check.
    property bool marked: false
    // Favourite badge, drawn top-left (the deletion mark owns top-right): filled when favourited,
    // an outline while the pointer is over the card or it is selected, hidden otherwise.
    property bool favorite: false
    property bool favoriteHint: false

    width: 160
    height: 100

    radius: 16

    color: "transparent"

    layer.enabled: true
    layer.smooth: true

    ClippingRectangle {

        anchors.fill: parent

        radius: root.radius


        Image {

            anchors.fill: parent


            source: root.imageSource


            fillMode: Image.PreserveAspectCrop


            asynchronous: true

            cache: true


            smooth: true


            sourceSize.width: root.width * 2

            sourceSize.height: root.height * 2
        }
    }

    // Selection overlay

    Rectangle {

        anchors.fill: parent

        radius: root.radius

        color: active
           ? Theme.wallpaperOverlay
           : "transparent"
    }

    // Selection outline

    Rectangle {

        anchors.fill: parent

        radius: root.radius


        color: "transparent"


        border.width: selected ? 3 : 0

        border.color: Theme.accent
    }

    // Deletion mark

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Theme.danger
        opacity: root.marked ? 0.35 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animationFast } }
    }

    Rectangle {
        objectName: "wallpaper-mark"
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 8
        width: 24
        height: 24
        radius: 12
        visible: root.marked
        color: Theme.danger
        SvgIcon {
            anchors.centerIn: parent
            source: "../assets/icons/check.svg"
            color: Theme.background
            size: 14
        }
    }

    Rectangle {
        objectName: "wallpaper-favorite"
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 8
        width: 24
        height: 24
        radius: 12
        visible: root.favorite || root.favoriteHint
        color: Qt.rgba(0, 0, 0, 0.55)
        SvgIcon {
            anchors.centerIn: parent
            source: root.favorite ? "../assets/icons/star-filled.svg" : "../assets/icons/star.svg"
            color: root.favorite ? Theme.warning : "white"
            size: 14
        }
    }
}
