pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

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

    signal copyRequested
    signal favoriteRequested(bool enabled)
    signal deleteRequested
    signal dragStarted(string key)
    signal dragMoved(point position)
    signal dragEnded
    signal dragCancelled

    readonly property int rowHeight: kind === "image" ? 110 : 96
    implicitHeight: rowHeight
    clip: true

    function escapeHtml(value: string): string {
        return String(value).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/\"/g, "&quot;").replace(/'/g, "&#39;");
    }

    function richPreview(value: string): string {
        const safe = escapeHtml(value).replace(/\r\n/g, "\n").replace(/\r/g, "\n").replace(/\n/g, "<br/>");
        return safe.replace(/https?:\/\/[^\s<>]+/gi, link => `<a href="${link}">${link}</a>`);
    }

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
        onClicked: root.copyRequested()
    }

    RowLayout {
        anchors.fill: parent
        anchors.topMargin: Tokens.padding.small
        anchors.bottomMargin: Tokens.padding.small
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium
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

        Image {
            Layout.preferredWidth: 76
            Layout.preferredHeight: 66
            visible: root.kind === "image" && root.thumbnail.length > 0
            source: root.thumbnail
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: true
        }

        Rectangle {
            Layout.preferredWidth: 76
            Layout.preferredHeight: 66
            visible: root.kind === "image" && root.thumbnail.length === 0
            radius: Tokens.rounding.medium
            color: Colours.palette.m3surfaceContainerHighest

            MaterialIcon {
                anchors.centerIn: parent
                text: "image"
                color: Style.muted
                fontStyle: Tokens.font.icon.large
            }
        }

        MaterialIcon {
            Layout.preferredWidth: root.kind === "files" ? 28 : 0
            Layout.preferredHeight: 30
            visible: root.kind === "files"
            text: "folder"
            color: Style.accent
            fontStyle: Tokens.font.icon.medium
        }

        MaterialIcon {
            Layout.preferredWidth: root.kind === "binary" ? 28 : 0
            Layout.preferredHeight: 30
            visible: root.kind === "binary"
            text: "data_object"
            color: Style.muted
            fontStyle: Tokens.font.icon.medium
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            Text {
                id: previewText
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 54
                Layout.maximumHeight: 54
                text: root.richPreview(root.preview)
                textFormat: Text.RichText
                color: Style.text
                linkColor: Style.accent
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                font: Tokens.font.body.small
                clip: true

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        const link = previewText.linkAt(mouse.x, mouse.y);
                        if (link.length > 0) {
                            if (/^https?:\/\//i.test(link))
                                Qt.openUrlExternally(link);
                        } else {
                            root.copyRequested();
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Text {
                    Layout.fillWidth: true
                    text: root.isLoading ? "Decoding…" : root.error.length ? root.error : `${root.kind || "clipboard"} · ${root.mime || "type unknown"} · ${root.byteSize} bytes`
                    color: root.error.length ? Style.error : Style.muted
                    elide: Text.ElideRight
                    font: Tokens.font.label.small
                }
            }
        }

        IconButton {
            icon: "star"
            type: IconButton.Text
            isToggle: true
            checked: root.isFavorite
            Accessible.name: root.isFavorite ? "Remove from favorites" : "Add to favorites"
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
            Accessible.name: root.favoritesTab ? "Delete favorite and matching history entries" : "Delete history entry"
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
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        height: 2
        z: 2.5
        color: Style.accent
        visible: root.insertionBefore
    }

}
