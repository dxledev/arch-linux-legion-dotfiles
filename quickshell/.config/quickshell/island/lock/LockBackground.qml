pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../services"
import "../styles"

Item {
    id: root
    property ShellScreen screen: null
    readonly property ScreencopyView snapshot: capture.item as ScreencopyView
    readonly property bool hasSnapshot: snapshot?.hasContent ?? false
    readonly property int blurRadius: ThemeService.settings.lockBlurRadius ?? 64
    readonly property real dimOpacity: (ThemeService.settings.lockDimOpacity ?? 40) / 100

    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: root.blurRadius > 0
            blur: 1
            blurMax: Math.max(1, root.blurRadius)
        }

        Image {
            anchors.fill: parent
            source: ThemeService.wallpaper ? "file:" + ThemeService.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            visible: !root.hasSnapshot
            asynchronous: true
        }

        Loader {
            id: capture
            anchors.fill: parent
            active: root.screen !== null
            sourceComponent: ScreencopyView {
                objectName: "lock-snapshot"
                captureSource: root.screen
                live: false
                paintCursor: false
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.background
        opacity: root.dimOpacity
    }
}
