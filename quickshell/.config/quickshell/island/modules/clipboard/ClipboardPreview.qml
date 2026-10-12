pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components"
import "../../styles"
import "ClipboardFormat.js" as ClipboardFormat

ColumnLayout {
    id: root

    required property var entry
    readonly property bool hasEntry: (entry.key || "").length > 0
    readonly property bool isImage: entry.payloadKind === "image"
    readonly property bool isColor: entry.payloadKind === "color"
    readonly property string openLink: ClipboardFormat.link(entry)
    readonly property color swatch: isColor ? entry.contentText.trim() : "transparent"
    readonly property string entryKey: entry.key || ""
    readonly property string entryIdentity: entry.contentHash || entryKey
    property string pendingCopyKey: ""
    property string pendingCopyIdentity: ""
    property string copiedIdentity: ""
    readonly property bool copying: pendingCopyKey.length > 0
    readonly property bool copied: entryIdentity.length > 0 && copiedIdentity === entryIdentity

    spacing: 10

    function copyEntry() {
        if (!hasEntry || copying)
            return;
        copyFeedback.stop();
        copiedIdentity = "";
        pendingCopyKey = entryKey;
        pendingCopyIdentity = entryIdentity;
        ClipboardService.copyEntry(entryKey, false);
    }

    onEntryIdentityChanged: {
        copiedIdentity = "";
        copyFeedback.stop();
    }

    Timer {
        id: copyFeedback
        interval: 1800
        onTriggered: root.copiedIdentity = ""
    }

    Connections {
        target: ClipboardService
        function onCopyFinished(key, success, dismissed) {
            if (key !== root.pendingCopyKey)
                return;
            root.pendingCopyKey = "";
            if (success && root.pendingCopyIdentity === root.entryIdentity) {
                root.copiedIdentity = root.entryIdentity;
                copyFeedback.restart();
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            UiText {
                objectName: "clipboard-preview-title"
                Layout.fillWidth: true
                text: root.hasEntry ? ClipboardFormat.singleLine(root.entry.previewText || "Clipboard entry") : "Preview"
                textFormat: Text.PlainText
                color: Theme.textPrimary
                font.pixelSize: 15
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            UiText {
                Layout.fillWidth: true
                visible: root.hasEntry
                text: root.entry.loading ? "Decoding…"
                    : ClipboardFormat.details(root.entry.payloadKind, root.entry.mimeType, root.entry.size)
                color: Theme.textMuted
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        IconButton {
            objectName: "clipboard-preview-pin"
            visible: root.hasEntry
            iconSource: root.entry.favorite ? "../assets/icons/star-filled.svg" : "../assets/icons/star.svg"
            iconColor: root.entry.favorite ? Theme.accent : Theme.textPrimary
            description: root.entry.favorite ? "Unpin entry" : "Pin entry"
            focusPolicy: Qt.NoFocus
            onClicked: ClipboardService.controller.setFavorite(root.entry.key, !root.entry.favorite)
        }

        IconButton {
            objectName: "clipboard-preview-open-link"
            visible: root.hasEntry && root.openLink.length > 0
            iconSource: "../assets/icons/external-link.svg"
            description: "Open link"
            focusPolicy: Qt.NoFocus
            onClicked: Qt.openUrlExternally(root.openLink)
        }

        IconButton {
            objectName: "clipboard-preview-copy"
            visible: root.hasEntry
            enabled: !root.copying
            iconSource: root.copied ? "../assets/icons/check.svg" : "../assets/icons/copy.svg"
            iconColor: root.copied ? Theme.success : Theme.textPrimary
            description: root.copied ? "Copied" : "Copy without closing"
            focusPolicy: Qt.NoFocus
            onClicked: root.copyEntry()
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.hasEntry && (root.entry.qrText || "").length > 0
        spacing: 4

        UiText {
            text: "QR code content"
            color: Theme.accent
            font.pixelSize: 11
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(90, qrContent.implicitHeight)
            clip: true

            TextArea {
                id: qrContent
                text: root.entry.qrText || ""
                textFormat: TextEdit.PlainText
                readOnly: true
                selectByMouse: true
                wrapMode: TextEdit.Wrap
                color: Theme.textPrimary
                selectionColor: Theme.accent
                selectedTextColor: Theme.background
                font.family: Theme.uiFontFamily
                font.pixelSize: 12
                background: Rectangle { color: Theme.surface; radius: 10 }
            }
        }
    }

    Rectangle {
        objectName: "clipboard-preview-body"
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 16
        color: Theme.surface
        clip: true

        Image {
            id: imagePreview
            anchors.fill: parent
            anchors.margins: 10
            visible: root.isImage
            source: root.isImage ? root.entry.imageUrl || root.entry.thumbnailUrl || "" : ""
            sourceSize.width: Math.max(1, width * 2)
            sourceSize.height: Math.max(1, height * 2)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            retainWhileLoading: true
            cache: false
        }

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 40
            visible: root.isColor
            spacing: 14

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(160, root.height / 3)
                radius: 14
                color: root.swatch
                border.width: 1
                border.color: Theme.border
            }

            UiText {
                Layout.fillWidth: true
                text: (root.entry.contentText || "").trim() + "\nRGB " + Math.round(root.swatch.r * 255) + ", "
                    + Math.round(root.swatch.g * 255) + ", " + Math.round(root.swatch.b * 255)
                color: Theme.textPrimary
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
            }
        }

        ScrollView {
            anchors.fill: parent
            visible: root.hasEntry && !root.isImage && !root.isColor
            clip: true

            TextArea {
                objectName: "clipboard-preview-text"
                text: root.hasEntry ? ClipboardFormat.body(root.entry) : ""
                textFormat: TextEdit.PlainText
                readOnly: true
                selectByMouse: true
                wrapMode: TextEdit.Wrap
                padding: 12
                color: Theme.textPrimary
                selectionColor: Theme.accent
                selectedTextColor: Theme.background
                font.family: root.entry.payloadKind === "code" || root.entry.payloadKind === "json"
                    ? "monospace" : Theme.uiFontFamily
                font.pixelSize: 12
                background: null
            }
        }

        UiText {
            anchors.centerIn: parent
            width: parent.width - 40
            visible: !root.hasEntry || (root.isImage && (imagePreview.source.toString().length === 0 || imagePreview.status === Image.Error))
            text: root.hasEntry ? "Image preview unavailable." : "Select an entry to preview it."
            color: Theme.textMuted
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }
}
