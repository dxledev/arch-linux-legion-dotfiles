import QtQuick
import QtQuick.Effects

import "../services"

// Blurred album-art backdrop with a darkening scrim and a hairline border.
// Fill it inside a clipping parent; the artwork is overscanned so the blur edge never shows.
Item {
    id: root

    property url source: MediaService.artUrl
    property real radius: 0
    property real scrim: 0.42

    readonly property bool ready: root.source.toString() !== "" && image.status === Image.Ready

    Item {
        anchors.fill: parent

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 64
            saturation: 0.25
        }

        Image {
            id: image

            anchors.centerIn: parent
            width: parent.width * 1.4
            height: parent.height * 1.4

            source: root.source
            asynchronous: true
            smooth: true
            fillMode: Image.PreserveAspectCrop

            opacity: status === Image.Ready ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.ready ? root.scrim : 0

        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: "#14FFFFFF"
    }
}
