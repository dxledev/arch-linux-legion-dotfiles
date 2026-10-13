import QtQuick
import Quickshell.Widgets
import "../../components"
import "../../services"
import "../../styles"

// One search result: thumbnail, resolution and favorites on hover, plus purity and library badges.
Item {
    id: root
    required property int index
    required property string wid
    required property string thumb
    required property string resolution
    required property int favorites
    required property int views
    required property string purity
    required property bool installed
    required property bool library
    required property string name
    readonly property bool selected: WallhavenService.selectedId === wid
    readonly property bool keyboardFocus: GridView.isCurrentItem && GridView.view.activeFocus
    signal activated()

    objectName: "wallhaven-card-" + wid

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 6
        radius: 16
        color: Theme.surface
        scale: hover.hovered ? 1.015 : 1
        Behavior on scale { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }

        ClippingRectangle {
            anchors.fill: parent
            radius: card.radius
            color: Theme.surfaceVariant
            Image {
                id: image
                anchors.fill: parent
                source: root.thumb
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                sourceSize.width: 420
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animationNormal } }
            }
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 46
                opacity: hover.hovered || root.selected || root.keyboardFocus ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animationFast } }
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: "#d0000000" }
                }
                UiText {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.right: root.library ? parent.right : undefined
                    anchors.rightMargin: 10
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 7
                    text: root.library ? root.name : root.resolution
                    elide: Text.ElideMiddle
                    color: "#ffffff"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
                Row {
                    visible: !root.library
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 7
                    spacing: 4
                    SvgIcon { anchors.verticalCenter: parent.verticalCenter; source: "../assets/icons/star-filled.svg"; size: 11; color: "#ffffff" }
                    UiText { text: root.favorites.toLocaleString(); color: "#ffffff"; font.pixelSize: 11 }
                }
            }
        }
        // Sketchy and NSFW results carry a colored dot so they stand out when mixed in.
        Rectangle {
            visible: root.purity !== "sfw"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 8
            width: 10; height: 10; radius: 5
            color: root.purity === "nsfw" ? Theme.danger : Theme.warning
            border.width: 1
            border.color: "#80000000"
        }
        Rectangle {
            visible: root.installed
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            width: 22; height: 22; radius: 11
            color: Theme.accent
            SvgIcon { anchors.centerIn: parent; source: "../assets/icons/check.svg"; size: 13; color: Theme.background }
        }
        Rectangle {
            anchors.fill: parent
            radius: card.radius
            color: "transparent"
            border.width: root.selected || root.keyboardFocus ? 3 : 0
            border.color: Theme.accent
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.activated() }
}
