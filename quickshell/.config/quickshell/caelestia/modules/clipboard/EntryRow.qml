pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import "Format.js" as Format

Item {
    id: root

    required property string entryKey
    required property string preview
    required property string searchable
    required property string kind
    required property string mime
    required property double byteSize
    required property string thumbnail
    required property bool isFavorite
    required property bool isLoading
    required property string error
    required property bool favoritesTab
    required property bool dragEnabled
    required property bool selected
    required property bool insertionBefore
    required property var controller
    property bool rowHovered: false

    signal selectRequested
    signal copyRequested
    signal favoriteRequested(bool enabled)
    signal deleteRequested
    signal dragStarted(string key)
    signal dragMoved(point position)
    signal dragEnded
    signal dragCancelled

    implicitHeight: Style.rowHeight
    clip: true

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.large
        color: root.selected ? Colours.palette.m3secondaryContainer : root.rowHovered ? Style.rowHover : Style.row
        border.width: 0
        border.color: Style.accent

        Behavior on color {
            CAnim {}
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: root.rowHovered = hovered
    }

    MouseArea {
        anchors.fill: parent
        z: 1
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: root.selectRequested()
        onDoubleClicked: root.copyRequested()
    }

    RowLayout {
        anchors.fill: parent
        anchors.topMargin: Style.rowPadding
        anchors.bottomMargin: Style.rowPadding
        anchors.leftMargin: Style.rowPadding
        anchors.rightMargin: Style.rowPadding
        spacing: Style.rowPadding
        z: 2

        Item {
            Layout.preferredWidth: 26
            Layout.fillHeight: true
            visible: root.favoritesTab

            MaterialIcon {
                anchors.centerIn: parent
                text: "drag_indicator"
                color: root.dragEnabled ? Style.muted : Colours.palette.m3outline
                fontStyle: Tokens.font.icon.medium
                opacity: 1
            }

            DragHandler {
                id: reorderDrag
                enabled: root.favoritesTab && root.dragEnabled
                target: null
                acceptedButtons: Qt.LeftButton
                onActiveChanged: {
                    if (active)
                        root.dragStarted(root.entryKey);
                    else
                        root.dragEnded();
                }
                onCanceled: root.dragCancelled()
                onCentroidChanged: {
                    if (active)
                        root.dragMoved(parent.mapToItem(root.ListView.view, centroid.position.x, centroid.position.y));
                }
            }

            ToolTip.visible: dragHover.hovered && root.favoritesTab && !root.dragEnabled
            ToolTip.text: "Clear search to reorder"
            ToolTip.delay: 500

            HoverHandler {
                id: dragHover
                cursorShape: root.favoritesTab && root.dragEnabled ? Qt.SizeAllCursor : Qt.ArrowCursor
            }
        }

        Rectangle {
            Layout.preferredWidth: Style.thumbnailSize
            Layout.preferredHeight: Style.thumbnailSize
            radius: Tokens.rounding.small
            color: root.kind === "color" ? root.preview.trim() : Colours.palette.m3surfaceContainerHighest

            Image {
                anchors.fill: parent
                visible: root.kind === "image" && root.thumbnail.length > 0
                source: root.thumbnail
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: root.kind !== "color" && !(root.kind === "image" && root.thumbnail.length > 0)
                text: ({image: "image", files: "folder", link: "link", code: "code", json: "data_object", binary: "memory"})[root.kind] || "description"
                color: Style.muted
                fontStyle: Tokens.font.icon.medium
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                Layout.fillWidth: true
                text: root.preview.replace(/[\r\n\t]+/g, " ")
                textFormat: Text.PlainText
                color: root.selected ? Style.accent : Style.text
                maximumLineCount: 1
                elide: Text.ElideRight
                font: Tokens.font.body.small
            }

            Text {
                Layout.fillWidth: true
                text: root.isLoading ? "Decoding…" : root.error.length ? root.error
                    : `${root.kind || "clipboard"} · ${root.mime || "type unknown"} · ${Format.bytes(root.byteSize)}`
                color: root.error.length ? Style.error : Style.muted
                elide: Text.ElideRight
                font: Tokens.font.label.small
            }
        }

        IconButton {
            icon: "star"
            type: IconButton.Text
            isToggle: true
            checked: root.isFavorite
            Accessible.name: root.isFavorite ? "Unpin entry" : "Pin entry"
            activeFocusOnTab: true
            stateLayer.manualHoverOverride: activeFocus
            onClicked: root.favoriteRequested(!root.isFavorite)
            Keys.onReturnPressed: root.favoriteRequested(!root.isFavorite)
            Keys.onSpacePressed: root.favoriteRequested(!root.isFavorite)
        }

        IconButton {
            type: IconButton.Text
            isRound: true
            icon: "delete"
            inactiveOnColour: Style.error
            Accessible.name: root.favoritesTab ? "Delete pinned entry and matching history entries" : "Delete history entry"
            activeFocusOnTab: true
            enabled: !root.controller.deleting
            stateLayer.manualHoverOverride: activeFocus
            onClicked: root.deleteRequested()
            Keys.onReturnPressed: root.deleteRequested()
            Keys.onSpacePressed: root.deleteRequested()
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Style.rowPadding
        anchors.rightMargin: Style.rowPadding
        height: 2
        z: 2.5
        color: Style.accent
        visible: root.insertionBefore
    }

}
