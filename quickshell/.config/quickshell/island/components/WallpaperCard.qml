import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import "../styles"

Rectangle {


    id: root

    property string imageSource: ""
    property bool selected: false
    // The applied wallpaper is blurred, dimmed and labelled "Active"; the keyboard selection gets the outline.
    property bool active: false
    // Blur of the applied wallpaper. The caller clamps these (see WallpaperService); the passes are
    // chained layers, each one blurring the previous result again.
    property bool blurActive: true
    property real blurStrength: 1
    property int blurRadius: 32
    property int blurPasses: 1
    // Marked for deletion: tinted with the danger colour and badged with a check.
    property bool marked: false
    // Favourite badge, drawn top-left (the deletion mark owns top-right): filled when favourited,
    // an outline while the pointer is over the card or it is selected, hidden otherwise.
    property bool favorite: false
    property bool favoriteHint: false

    readonly property bool blurShown: active && blurActive

    width: 160
    height: 100

    radius: 16

    color: "transparent"

    layer.enabled: true
    layer.smooth: true

    ClippingRectangle {

        anchors.fill: parent

        radius: root.radius


        // Passes two and three wrap the first; a layer that is off draws its content untouched. Each wrapper is
        // scaled up a little so its own blur fringe falls outside the card.
        Item {
            id: outerPass
            anchors.fill: parent
            scale: root.blurShown && root.blurPasses >= 3 ? 1.2 : 1
            layer.enabled: root.blurShown && root.blurPasses >= 3
            layer.effect: MultiEffect { autoPaddingEnabled: false; blurEnabled: true; blur: root.blurStrength; blurMax: root.blurRadius }

            Item {
                id: middlePass
                anchors.fill: parent
                scale: root.blurShown && root.blurPasses >= 2 ? 1.2 : 1
                layer.enabled: root.blurShown && root.blurPasses >= 2
                layer.effect: MultiEffect { autoPaddingEnabled: false; blurEnabled: true; blur: root.blurStrength; blurMax: root.blurRadius }

                Image {
                    anchors.fill: parent
                    source: root.imageSource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                    sourceSize.width: root.width * 2
                    sourceSize.height: root.height * 2

                    // Blurring fades the texture's edges to transparent; the overscan crops that fringe.
                    scale: root.blurShown ? 1.4 : 1
                    layer.enabled: root.blurShown
                    layer.effect: MultiEffect { autoPaddingEnabled: false; blurEnabled: true; blur: root.blurStrength; blurMax: root.blurRadius }
                }
            }
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

    // A dark chip like the star badge's keeps the label readable over any wallpaper and theme.
    Rectangle {
        objectName: "wallpaper-active-label"
        anchors.centerIn: parent
        visible: root.active
        width: activeText.implicitWidth + 24
        height: activeText.implicitHeight + 10
        radius: height / 2
        color: Qt.rgba(0, 0, 0, 0.55)
        UiText {
            id: activeText
            anchors.centerIn: parent
            text: "Active"
            color: "white"
            font.pixelSize: 13
            font.bold: true
        }
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
