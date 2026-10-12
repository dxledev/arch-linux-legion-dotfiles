pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../styles"
import "ClipboardFormat.js" as ClipboardFormat

Item {
    id: root

    required property string entryKey
    required property string preview
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
    required property bool deleteEnabled

    signal selectRequested
    signal copyRequested
    signal favoriteRequested(bool enabled)
    signal deleteRequested
    signal dragStarted(string key)
    signal dragMoved(point position)
    signal dragEnded
    signal dragCancelled

    implicitHeight: 60

    Rectangle {
        objectName: "clipboard-row-background"
        anchors.fill: parent
        radius: 14
        color: root.selected ? Theme.surfaceVariant : rowHover.hovered ? Theme.buttonHover : Theme.surface
        border.width: root.selected ? 1 : 0
        border.color: Theme.accent
        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
    }

    HoverHandler {
        id: rowHover
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        objectName: "clipboard-row-mouse"
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.selectRequested()
        onDoubleClicked: root.copyRequested()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        spacing: 10

        Item {
            objectName: "clipboard-row-grip"
            Layout.preferredWidth: 18
            Layout.fillHeight: true
            visible: root.favoritesTab

            SvgIcon {
                anchors.centerIn: parent
                source: "../assets/icons/grip-vertical.svg"
                size: 16
                color: root.dragEnabled ? Theme.textSecondary : Theme.textMuted
                opacity: root.dragEnabled ? 1 : 0.5
            }

            HoverHandler {
                id: gripHover
                cursorShape: root.dragEnabled ? Qt.SizeAllCursor : Qt.ArrowCursor
            }

            IslandTooltip {
                parent: root
                visible: gripHover.hovered && !root.dragEnabled
                text: "Clear search to reorder"
            }

            DragHandler {
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
        }

        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 10
            color: root.kind === "color" ? root.preview.trim() : Theme.card
            clip: true

            Image {
                anchors.fill: parent
                visible: root.kind === "image" && root.thumbnail.length > 0
                source: visible ? root.thumbnail : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            SvgIcon {
                anchors.centerIn: parent
                visible: root.kind !== "color" && !(root.kind === "image" && root.thumbnail.length > 0)
                source: ClipboardFormat.kindIcon(root.kind)
                size: 18
                color: root.selected ? Theme.accent : Theme.textSecondary
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            UiText {
                Layout.fillWidth: true
                text: ClipboardFormat.singleLine(root.preview)
                textFormat: Text.PlainText
                color: root.selected ? Theme.accent : Theme.textPrimary
                font.pixelSize: 13
                maximumLineCount: 1
                elide: Text.ElideRight
            }

            UiText {
                Layout.fillWidth: true
                text: root.isLoading ? "Decoding…" : root.error.length > 0 ? root.error
                    : ClipboardFormat.details(root.kind, root.mime, root.byteSize)
                color: root.error.length > 0 ? Theme.danger : Theme.textMuted
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        IconButton {
            objectName: "clipboard-row-pin"
            implicitWidth: 32
            implicitHeight: 32
            padding: 8
            iconSource: root.isFavorite ? "../assets/icons/star-filled.svg" : "../assets/icons/star.svg"
            iconColor: root.isFavorite ? Theme.accent : Theme.textSecondary
            description: root.isFavorite ? "Unpin entry" : "Pin entry"
            focusPolicy: Qt.NoFocus
            onClicked: root.favoriteRequested(!root.isFavorite)
        }

        IconButton {
            objectName: "clipboard-row-delete"
            implicitWidth: 32
            implicitHeight: 32
            padding: 8
            iconSource: "../assets/icons/trash.svg"
            iconColor: Theme.danger
            description: root.favoritesTab ? "Delete pinned entry and matching history" : "Delete entry"
            enabled: root.deleteEnabled
            opacity: enabled ? 1 : 0.5
            focusPolicy: Qt.NoFocus
            onClicked: root.deleteRequested()
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: -3
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        height: 2
        radius: 1
        color: Theme.accent
        visible: root.insertionBefore
    }
}
